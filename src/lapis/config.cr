require "yaml"
require "./output_formats"

module Lapis
  class LiveReloadConfig
    include YAML::Serializable

    property enabled : Bool = true
    property websocket_path : String = "/__lapis_live_reload__"
    property debounce_ms : Int32 = 100
    property ignore_patterns : Array(String) = [".git", "node_modules", ".DS_Store", "*.tmp", "*.swp"]
    property watch_content : Bool = true
    property watch_layouts : Bool = true
    property watch_static : Bool = true
    property watch_config : Bool = true

    def initialize
    end
  end
  class BuildConfig
    include YAML::Serializable

    property incremental : Bool = true
    property parallel : Bool = true
    property cache_dir : String = ".lapis-cache"
    property max_workers : Int32 = 4
    property clean_build : Bool = false

    def initialize(@incremental = true, @parallel = true, @cache_dir = ".lapis-cache", @max_workers = 4, @clean_build = false)
    end

    def max_workers : Int32
      # Use system CPU count but cap at reasonable limit
      [@max_workers, System.cpu_count, 8].min
    end
  end

  class Config
    include YAML::Serializable

    property title : String = "Lapis Site"
    property baseurl : String = "http://localhost:3000"
    property description : String = "A site built with Lapis"
    property author : String = "Site Author"
    property theme : String = "default"
    property output_dir : String = "public"
    property permalink : String = "/:year/:month/:day/:title/"
    property port : Int32 = 3000
    property host : String = "localhost"
    property root_dir : String = "."

    # Build configuration
    @[YAML::Field(key: "build")]
    property build_config : BuildConfig = BuildConfig.new

    # Live reload configuration
    @[YAML::Field(key: "live_reload")]
    property live_reload_config : LiveReloadConfig = LiveReloadConfig.new

    @[YAML::Field(key: "markdown")]
    property markdown_config : MarkdownConfig?

    # Logging configuration
    property debug : Bool = false
    property log_file : String? = nil
    property log_level : String = "info"

    # Plugin configuration
    property plugins : Hash(String, YAML::Any) = {} of String => YAML::Any

    # Output format manager for multi-format rendering (initialized lazily)
    @[YAML::Field(ignore: true)]
    @output_formats : OutputFormatManager?

    def initialize(@title = "Lapis Site", @baseurl = "http://localhost:3000", @description = "A site built with Lapis", @author = "Site Author", @theme = "default", @output_dir = "public", @permalink = "/:year/:month/:day/:title/", @port = 3000, @host = "localhost", @markdown_config = nil)
    end

    def output_formats : OutputFormatManager
      @output_formats ||= OutputFormatManager.new
    end

    def self.load(path : String = "config.yml") : Config
      if File.exists?(path)
        content = File.read(path)
        yaml_data = YAML.parse(content).as_h
        config = from_yaml(content)
        config.validate

        # Load output formats from YAML data
        config.output_formats.load_from_config(yaml_data.transform_keys(&.to_s))

        config
      else
        puts "Warning: No config.yml found, using defaults"
        Config.new
      end
    rescue ex : YAML::ParseException
      puts "Error parsing config.yml: #{ex.message}"
      exit(1)
    end

    def validate
      if @output_dir.empty?
        @output_dir = "public"
      end

      if @permalink.empty?
        @permalink = "/:title/"
      end

      if @port < 1 || @port > 65535
        @port = 3000
      end
    end

    def content_dir : String
      "content"
    end

    def layouts_dir : String
      "layouts"
    end

    def static_dir : String
      "static"
    end

    def theme_dir : String
      resolve_theme_path(@theme)
    end

    # Resolve theme path with fallback logic:
    # 1. Check site's themes directory first (user custom themes)
    # 2. Check built-in themes directory (project themes)
    # 3. Default to built-in if neither exists
    def resolve_theme_path(theme_name : String) : String
      # 1. Site-specific theme (user's custom theme)
      site_theme_path = File.join("themes", theme_name)
      if Dir.exists?(site_theme_path)
        return site_theme_path
      end

      # 2. Built-in theme (relative to Lapis installation)
      builtin_theme_path = find_builtin_theme_path(theme_name)
      if !builtin_theme_path.nil? && Dir.exists?(builtin_theme_path)
        return builtin_theme_path
      end

      # 3. Fallback to default built-in theme
      default_builtin = find_builtin_theme_path("default")
      if !default_builtin.nil? && Dir.exists?(default_builtin)
        return default_builtin
      end

      # 4. Last resort: assume local themes directory
      File.join("themes", "default")
    end

    # Find built-in theme path relative to the binary location
    private def find_builtin_theme_path(theme_name : String) : String?
      # Try to find themes relative to where lapis is being executed
      possible_paths = [
        # When running from project root during development
        File.join("..", "themes", theme_name),
        # When running as installed binary (future)
        File.join(File.dirname(Process.executable_path || ""), "..", "themes", theme_name),
        # When running from exampleSite during development
        File.join("..", "themes", theme_name)
      ]

      possible_paths.each do |path|
        if Dir.exists?(path)
          return path
        end
      end

      nil
    end

    def posts_dir : String
      File.join(content_dir, "posts")
    end

    def server_url : String
      "#{host}:#{port}"
    end

    def markdown : MarkdownConfig
      @markdown_config ||= MarkdownConfig.new(
        syntax_highlighting: true,
        toc: true,
        smart_quotes: true,
        footnotes: true,
        tables: true
      )
    end
  end

  class MarkdownConfig
    include YAML::Serializable

    property syntax_highlighting : Bool = true
    property toc : Bool = true
    property smart_quotes : Bool = true
    property footnotes : Bool = true
    property tables : Bool = true

    def initialize(@syntax_highlighting = true, @toc = true, @smart_quotes = true, @footnotes = true, @tables = true)
    end
    private def self.read_config_file(path : String) : String
      File.open(path, "r") do |file|
        file.set_encoding("UTF-8")
        file.gets_to_end
      end
    rescue ex : File::NotFoundError
      raise "Config file not found: #{path}"
    rescue ex : IO::Error
      raise "Error reading config file #{path}: #{ex.message}"
    end
  end
end