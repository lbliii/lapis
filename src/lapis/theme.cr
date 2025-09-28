require "yaml"
require "./logger"

module Lapis
  # Standard interface for Lapis themes
  # Both shard-based and directory-based themes implement this
  abstract class Theme
    property name : String
    property version : String
    property description : String
    property author : String
    property theme_path : String

    def initialize(@theme_path : String)
      @name = ""
      @version = "0.0.0"
      @description = ""
      @author = ""
      load_theme_config
    end

    # Theme configuration from theme.yml
    def load_theme_config
      config_file = File.join(@theme_path, "theme.yml")
      return unless File.exists?(config_file)

      begin
        config = YAML.parse(File.read(config_file)).as_h
        @name = config["name"]?.try(&.as_s) || File.basename(@theme_path)
        @version = config["version"]?.try(&.as_s) || "0.0.0"
        @description = config["description"]?.try(&.as_s) || ""
        @author = config["author"]?.try(&.as_s) || ""
        Logger.debug("Loaded theme config", name: @name, version: @version)
      rescue ex
        Logger.warn("Failed to parse theme config", path: config_file, error: ex.message)
      end
    end

    # Required directories for a valid theme
    def required_directories : Array(String)
      ["layouts"]
    end

    # Optional directories
    def optional_directories : Array(String)
      ["static", "assets", "data", "i18n"]
    end

    # Validate theme structure
    def valid? : Bool
      required_directories.all? do |dir|
        Dir.exists?(File.join(@theme_path, dir))
      end
    end

    # Get all available layouts
    def layouts : Array(String)
      layouts_dir = File.join(@theme_path, "layouts")
      return [] of String unless Dir.exists?(layouts_dir)

      layouts = [] of String
      scan_layouts_dir(layouts_dir, "", layouts)
      layouts.sort
    end

    # Get theme assets for copying
    def assets : Hash(String, String)
      assets = {} of String => String
      static_dir = File.join(@theme_path, "static")
      return assets unless Dir.exists?(static_dir)

      scan_assets_dir(static_dir, "", assets)
      assets
    end

    # Theme-specific configuration
    def config : Hash(String, YAML::Any)
      config_file = File.join(@theme_path, "config.yml")
      return {} of String => YAML::Any unless File.exists?(config_file)

      begin
        YAML.parse(File.read(config_file)).as_h
      rescue
        {} of String => YAML::Any
      end
    end

    private def scan_layouts_dir(dir : String, prefix : String, layouts : Array(String))
      Dir.each_child(dir) do |child|
        child_path = File.join(dir, child)
        relative_path = prefix.empty? ? child : File.join(prefix, child)

        if Dir.exists?(child_path)
          scan_layouts_dir(child_path, relative_path, layouts)
        elsif child.ends_with?(".html")
          layouts << relative_path
        end
      end
    end

    private def scan_assets_dir(dir : String, prefix : String, assets : Hash(String, String))
      Dir.each_child(dir) do |child|
        child_path = File.join(dir, child)
        relative_path = prefix.empty? ? child : File.join(prefix, child)

        if Dir.exists?(child_path)
          scan_assets_dir(child_path, relative_path, assets)
        else
          assets[relative_path] = child_path
        end
      end
    end
  end

  # Directory-based theme (themes/theme-name/)
  class DirectoryTheme < Theme
  end

  # Shard-based theme (lib/theme-name/)
  class ShardTheme < Theme
    property shard_name : String

    def initialize(@theme_path : String, @shard_name : String)
      super(@theme_path)
    end

    # Check if this is a proper Lapis theme shard
    def valid_shard? : Bool
      shard_yml = File.join(@theme_path, "shard.yml")
      return false unless File.exists?(shard_yml)

      begin
        shard_config = YAML.parse(File.read(shard_yml)).as_h
        # Check if it declares itself as a Lapis theme
        targets = shard_config["targets"]?.try(&.as_h)
        return false unless targets

        # Look for lapis-theme target or special markers
        targets.has_key?("lapis-theme") ||
          shard_config["description"]?.try(&.as_s.includes?("lapis theme")) == true
      rescue
        false
      end
    end
  end

  # Embedded theme (shipped with Lapis)
  class EmbeddedTheme < Theme
    def initialize
      # For now, point to the bundled theme directory
      # In production, this could use Crystal's embedded files
      theme_path = File.join(__DIR__, "..", "..", "themes", "default")
      super(theme_path)
      @name = "default"
      @version = "bundled"
      @description = "Default Lapis theme"
      @author = "Lapis Team"
    end
  end
end