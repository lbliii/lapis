require "file_utils"
require "log"
require "./logger"
require "./exceptions"

module Lapis
  # Manages theme resolution, loading, and asset handling
  # Supports multiple theme sources with proper priority ordering
  class ThemeManager
    property current_theme : String
    property theme_paths : Array(String) = [] of String
    property resolved_paths : Hash(String, String) = {} of String => String
    property custom_theme_dir : String?

    def initialize(@current_theme : String, project_root : String = ".", theme_dir : String? = nil)
      @project_root = project_root
      @global_themes_dir = File.expand_path("~/.lapis/themes")

      # Use custom theme_dir if provided
      if theme_dir
        @custom_theme_dir = theme_dir
      end

      build_theme_paths
      resolve_theme_locations
      Logger.info("Theme manager initialized", theme: @current_theme, paths: @theme_paths.size)
    end

    # Main theme resolution - finds templates, assets, etc.
    def resolve_file(file_path : String, file_type : String = "layout") : String?
      search_paths = case file_type
                     when "layout"
                       layout_search_paths(file_path)
                     when "partial"
                       partial_search_paths(file_path)
                     when "asset"
                       asset_search_paths(file_path)
                     else
                       general_search_paths(file_path)
                     end

      search_paths.each do |path|
        if File.exists?(path)
          Logger.debug("Resolved file", file: file_path, resolved_path: path, type: file_type)
          return path
        end
      end

      Logger.warn("File not found in any theme location", file: file_path, type: file_type)
      nil
    end

    # Get all asset files from all theme sources (for copying to output)
    def collect_all_assets : Hash(String, String)
      assets = {} of String => String

      # Collect from all theme paths (reverse order for proper precedence)
      @theme_paths.reverse.each do |theme_path|
        static_dir = File.join(theme_path, "static")
        next unless Dir.exists?(static_dir)

        collect_assets_from_dir(static_dir, "", assets)
      end

      # User static assets override everything
      user_static = File.join(@project_root, "static")
      if Dir.exists?(user_static)
        collect_assets_from_dir(user_static, "", assets)
      end

      Logger.info("Collected assets", count: assets.size)
      assets
    end

    # Check if current theme is properly configured and available
    def theme_available? : Bool
      layout_file = resolve_file("baseof.html", "layout") ||
                    resolve_file("default.html", "layout") ||
                    resolve_file("index.html", "layout")
      !layout_file.nil?
    end

    # Get theme metadata if available
    def theme_info : Hash(String, String)
      info_file = resolve_file("theme.yml", "config")
      return {} of String => String unless info_file

      begin
        data = YAML.parse(File.read(info_file)).as_h
        data.transform_keys(&.to_s).transform_values(&.to_s)
      rescue ex : YAML::ParseException
        Logger.warn("Failed to parse theme.yml", file: info_file, error: ex.message)
        {} of String => String
      rescue ex : File::NotFoundError
        Logger.debug("Theme config file not found", file: info_file)
        {} of String => String
      rescue ex
        Logger.error("Unexpected error reading theme info", file: info_file, error: ex.message)
        {} of String => String
      end
    end

    # Detect and validate shard-based themes
    def detect_shard_themes : Array(ShardTheme)
      shard_themes = [] of ShardTheme

      lib_dir = File.join(@project_root, "lib")
      return shard_themes unless Dir.exists?(lib_dir)

      Dir.each_child(lib_dir) do |shard_name|
        shard_path = File.join(lib_dir, shard_name)
        next unless Dir.exists?(shard_path)

        # Check if this shard is a Lapis theme
        if lapis_theme_shard?(shard_path)
          theme = ShardTheme.new(shard_path, shard_name)
          if theme.valid_shard? && theme.valid?
            shard_themes << theme
            Logger.debug("Found valid theme shard", name: shard_name, path: shard_path)
          else
            Logger.warn("Invalid theme shard found", name: shard_name, path: shard_path)
          end
        end
      end

      shard_themes
    end

    # Get available themes from all sources
    def list_available_themes : Hash(String, String)
      themes = {} of String => String

      # 1. Local themes in themes/ directory
      themes_dir = File.join(@project_root, "themes")
      if Dir.exists?(themes_dir)
        Dir.each_child(themes_dir) do |theme_name|
          theme_path = File.join(themes_dir, theme_name)
          if Dir.exists?(theme_path) && Dir.exists?(File.join(theme_path, "layouts"))
            themes[theme_name] = "local"
          end
        end
      end

      # 2. Shard-based themes
      detect_shard_themes.each do |shard_theme|
        themes[shard_theme.name] = "shard"
      end

      # 3. Global themes
      if Dir.exists?(@global_themes_dir)
        Dir.each_child(@global_themes_dir) do |theme_name|
          theme_path = File.join(@global_themes_dir, theme_name)
          if Dir.exists?(theme_path) && Dir.exists?(File.join(theme_path, "layouts"))
            themes[theme_name] ||= "global" # Don't override local/shard themes
          end
        end
      end

      themes
    end

    # Check if a theme is available from any source
    def theme_exists?(theme_name : String) : Bool
      list_available_themes.has_key?(theme_name)
    end

    # Get the source type of a theme (local, shard, global, embedded)
    def theme_source(theme_name : String) : String?
      if theme_name == "default"
        return "embedded"
      end

      list_available_themes[theme_name]?
    end

    private def build_theme_paths
      @theme_paths.clear

      # 0. Custom theme directory (highest priority)
      if @custom_theme_dir
        custom_path = File.expand_path(@custom_theme_dir.try { |dir| dir } || "themes/default", @project_root)
        @theme_paths << custom_path if Dir.exists?(custom_path)
      end

      # 1. Project-local themes directory
      project_themes = File.join(@project_root, "themes", @current_theme)
      @theme_paths << project_themes if Dir.exists?(project_themes)

      # 2. Shard-based themes (lib/theme-name)
      shard_theme_path = File.join(@project_root, "lib", @current_theme)
      @theme_paths << shard_theme_path if Dir.exists?(shard_theme_path)

      # Alternative shard naming patterns
      ["lapis-theme-#{@current_theme}", "lapis_theme_#{@current_theme}"].each do |shard_name|
        shard_path = File.join(@project_root, "lib", shard_name)
        @theme_paths << shard_path if Dir.exists?(shard_path)
      end

      # 3. Global themes directory
      global_theme = File.join(@global_themes_dir, @current_theme)
      @theme_paths << global_theme if Dir.exists?(global_theme)

      # 4. Embedded default theme (always available as fallback)
      if @current_theme == "default"
        embedded_theme = File.join(@project_root, "themes", "default")
        @theme_paths << embedded_theme if Dir.exists?(embedded_theme)
      end

      Logger.debug("Built theme paths", theme: @current_theme, paths: @theme_paths)
    end

    private def resolve_theme_locations
      @resolved_paths.clear
      @theme_paths.each_with_index do |path, index|
        @resolved_paths["priority_#{index}"] = path
      end
    end

    private def layout_search_paths(file_path : String) : Array(String)
      paths = [] of String

      # 1. User layout overrides (highest priority)
      user_layout = File.join(@project_root, "layouts", file_path)
      paths << user_layout

      # 2. Theme layouts
      @theme_paths.each do |theme_path|
        theme_layout = File.join(theme_path, "layouts", file_path)
        paths << theme_layout

        # Also check _default subdirectory
        default_layout = File.join(theme_path, "layouts", "_default", file_path)
        paths << default_layout
      end

      paths
    end

    private def partial_search_paths(file_path : String) : Array(String)
      paths = [] of String

      # 1. User partials
      user_partial = File.join(@project_root, "layouts", "partials", file_path)
      paths << user_partial

      # 2. Theme partials
      @theme_paths.each do |theme_path|
        theme_partial = File.join(theme_path, "layouts", "partials", file_path)
        paths << theme_partial
      end

      paths
    end

    private def asset_search_paths(file_path : String) : Array(String)
      paths = [] of String

      # 1. User static assets
      user_asset = File.join(@project_root, "static", file_path)
      paths << user_asset

      # 2. Theme static assets
      @theme_paths.each do |theme_path|
        theme_asset = File.join(theme_path, "static", file_path)
        paths << theme_asset
      end

      paths
    end

    private def general_search_paths(file_path : String) : Array(String)
      paths = [] of String

      # Search in theme root and common subdirectories
      @theme_paths.each do |theme_path|
        paths << File.join(theme_path, file_path)
        paths << File.join(theme_path, "config", file_path)
        paths << File.join(theme_path, "data", file_path)
      end

      paths
    end

    # Validate a theme's structure and requirements
    def validate_theme(theme_path : String) : Hash(String, String | Bool)
      result = {
        "valid"              => false,
        "has_layouts"        => false,
        "has_baseof"         => false,
        "has_default_layout" => false,
        "has_theme_config"   => false,
        "error"              => "",
      } of String => String | Bool

      begin
        # Check if theme directory exists
        unless Dir.exists?(theme_path)
          result["error"] = "Theme directory does not exist"
          return result
        end

        # Check for layouts directory
        layouts_dir = File.join(theme_path, "layouts")
        unless Dir.exists?(layouts_dir)
          result["error"] = "Missing layouts directory"
          return result
        end
        result["has_layouts"] = true

        # Check for essential layout files
        baseof_html_default = File.join(layouts_dir, "_default", "baseof.html")
        baseof_html_root = File.join(layouts_dir, "baseof.html")
        result["has_baseof"] = File.exists?(baseof_html_default) || File.exists?(baseof_html_root)

        default_layout = File.join(layouts_dir, "_default", "single.html") ||
                         File.join(layouts_dir, "index.html")
        result["has_default_layout"] = File.exists?(File.join(layouts_dir, "_default", "single.html")) ||
                                       File.exists?(File.join(layouts_dir, "index.html"))

        # Check for theme configuration
        theme_config = File.join(theme_path, "theme.yml")
        result["has_theme_config"] = File.exists?(theme_config)

        # Theme is valid if it has layouts and at least one layout file
        result["valid"] = result["has_layouts"].as(Bool) &&
                          (result["has_baseof"].as(Bool) || result["has_default_layout"].as(Bool))
      rescue ex
        result["error"] = "Validation error: #{ex.message}"
      end

      result
    end

    # Validate a shard-based theme
    def validate_shard_theme(shard_path : String) : Hash(String, String | Bool)
      result = validate_theme(shard_path)

      # Additional shard-specific validations
      shard_yml = File.join(shard_path, "shard.yml")
      unless File.exists?(shard_yml)
        result["valid"] = false
        result["error"] = "Missing shard.yml file"
        return result
      end

      begin
        shard_config = YAML.parse(File.read(shard_yml)).as_h

        # Validate shard.yml structure
        unless shard_config["name"]?
          result["valid"] = false
          result["error"] = "shard.yml missing name field"
          return result
        end

        unless shard_config["version"]?
          result["valid"] = false
          result["error"] = "shard.yml missing version field"
          return result
        end

        # Check if it's properly marked as a Lapis theme
        is_theme_shard = false

        if targets = shard_config["targets"]?.try(&.as_h)
          is_theme_shard = targets.has_key?("lapis-theme")
        end

        if description = shard_config["description"]?.try(&.as_s)
          is_theme_shard ||= description.downcase.includes?("lapis theme")
        end

        if name = shard_config["name"]?.try(&.as_s)
          is_theme_shard ||= name.starts_with?("lapis-theme-") || name.starts_with?("lapis_theme_")
        end

        unless is_theme_shard
          result["valid"] = false
          result["error"] = "Shard not identified as a Lapis theme"
          return result
        end
      rescue ex
        result["valid"] = false
        result["error"] = "Invalid shard.yml: #{ex.message}"
      end

      result
    end

    # Check if a directory contains a valid Lapis theme shard
    private def lapis_theme_shard?(shard_path : String) : Bool
      shard_yml = File.join(shard_path, "shard.yml")
      return false unless File.exists?(shard_yml)

      # Must have layouts directory
      return false unless Dir.exists?(File.join(shard_path, "layouts"))

      begin
        shard_config = YAML.parse(File.read(shard_yml)).as_h

        # Check if it's explicitly marked as a Lapis theme
        if targets = shard_config["targets"]?.try(&.as_h)
          return true if targets.has_key?("lapis-theme")
        end

        # Check description for Lapis theme keywords
        if description = shard_config["description"]?.try(&.as_s)
          return true if description.downcase.includes?("lapis theme")
        end

        # Check if name suggests it's a theme
        if name = shard_config["name"]?.try(&.as_s)
          return true if name.starts_with?("lapis-theme-") || name.starts_with?("lapis_theme_")
        end

        false
      rescue ex : YAML::ParseException
        Logger.warn("Failed to parse shard.yml for theme detection", path: shard_yml, error: ex.message)
        false
      rescue ex : File::NotFoundError
        Logger.debug("Shard.yml not found during theme detection", path: shard_yml)
        false
      rescue ex
        Logger.error("Unexpected error during shard theme detection", path: shard_yml, error: ex.message)
        false
      end
    end

    private def collect_assets_from_dir(dir : String, prefix : String, assets : Hash(String, String))
      Dir.each_child(dir) do |child|
        child_path = File.join(dir, child)
        relative_path = prefix.empty? ? child : File.join(prefix, child)

        if Dir.exists?(child_path)
          collect_assets_from_dir(child_path, relative_path, assets)
        else
          assets[relative_path] = child_path
        end
      end
    rescue ex : File::NotFoundError
      Logger.debug("Asset directory not found", dir: dir)
    rescue ex : File::AccessDeniedError
      Logger.warn("Access denied to asset directory", dir: dir, error: ex.message)
    rescue ex
      Logger.error("Error collecting assets from directory", dir: dir, error: ex.message)
    end
  end

  # Exception for theme-related errors
  class ThemeError < LapisError
    def initialize(message : String)
      super("Theme Error: #{message}")
    end
  end
end
