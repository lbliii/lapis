require "yaml"
require "uri"
require "./output_formats"
require "./content_types"

module Lapis
  # Maximum number of workers allowed for parallel processing
  MAX_WORKERS_LIMIT = 8

  # Live reload watch options as flags
  @[Flags]
  enum WatchOptions
    Content # 1
    Layouts # 2
    Static  # 4
    Config  # 8
  end

  # Build configuration options as flags
  @[Flags]
  enum BuildOptions
    Incremental # 1
    Parallel    # 2
    CleanBuild  # 4
  end

  # Asset bundling options as flags
  @[Flags]
  enum BundlingOptions
    Enabled    # 1
    Minify     # 2
    SourceMaps # 4
    Autoprefix # 8
    TreeShake  # 16
  end

  class LiveReloadConfig
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property enabled : Bool = true

    @[YAML::Field(emit_null: true)]
    property websocket_path : String = "/__lapis_live_reload__"

    @[YAML::Field(emit_null: true)]
    property debounce_ms : Int32 = 100

    @[YAML::Field(emit_null: true)]
    property ignore_patterns : Array(String) = [".git", "node_modules", ".DS_Store", "*.tmp", "*.swp"]

    @[YAML::Field(emit_null: true)]
    property watch_options : WatchOptions = WatchOptions::Content | WatchOptions::Layouts | WatchOptions::Static | WatchOptions::Config

    # Legacy properties - ignored during YAML deserialization
    @[YAML::Field(ignore: true)]
    property watch_content : Bool = true

    @[YAML::Field(ignore: true)]
    property watch_layouts : Bool = true

    @[YAML::Field(ignore: true)]
    property watch_static : Bool = true

    @[YAML::Field(ignore: true)]
    property watch_config : Bool = true

    def initialize
    end

    # Convenience methods for backward compatibility and easier access
    def watch_content? : Bool
      @watch_content
    end

    def watch_layouts? : Bool
      @watch_layouts
    end

    def watch_static? : Bool
      @watch_static
    end

    def watch_config? : Bool
      @watch_config
    end

    def watch_content=(value : Bool)
      @watch_content = value
    end

    def watch_layouts=(value : Bool)
      @watch_layouts = value
    end

    def watch_static=(value : Bool)
      @watch_static = value
    end

    def watch_config=(value : Bool)
      @watch_config = value
    end
  end

  class BuildConfig
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property build_options : BuildOptions = BuildOptions::Incremental | BuildOptions::Parallel

    @[YAML::Field(emit_null: true)]
    property cache_dir : String = ".lapis-cache"

    @[YAML::Field(emit_null: true)]
    property max_workers : Int32 = 4

    # Legacy property - ignored during YAML deserialization
    @[YAML::Field(ignore: true)]
    property clean_build : Bool = false

    # Legacy properties for incremental and parallel
    @[YAML::Field(ignore: true)]
    property incremental : Bool = true

    @[YAML::Field(ignore: true)]
    property parallel : Bool = true

    def initialize(@build_options = BuildOptions::Incremental | BuildOptions::Parallel, @cache_dir = ".lapis-cache", @max_workers = 4)
    end

    def max_workers : Int32
      # Use system CPU count but cap at reasonable limit
      [@max_workers, System.cpu_count, MAX_WORKERS_LIMIT].min.to_i32
    end

    # Convenience methods for backward compatibility and easier access
    def incremental? : Bool
      @incremental
    end

    def parallel? : Bool
      @parallel
    end

    def clean_build? : Bool
      @clean_build
    end

    def incremental=(value : Bool)
      @incremental = value
    end

    def parallel=(value : Bool)
      @parallel = value
    end

    def clean_build=(value : Bool)
      @clean_build = value
    end
  end

  class BundlingConfig
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property bundling_options : BundlingOptions = BundlingOptions::Enabled | BundlingOptions::Minify | BundlingOptions::Autoprefix

    # Legacy properties - ignored during YAML deserialization
    @[YAML::Field(ignore: true)]
    property enabled : Bool = true

    @[YAML::Field(ignore: true)]
    property minify : Bool = true

    @[YAML::Field(ignore: true)]
    property source_maps : Bool = false

    @[YAML::Field(ignore: true)]
    property autoprefix : Bool = true

    @[YAML::Field(ignore: true)]
    property tree_shake : Bool = false

    def initialize(@bundling_options = BundlingOptions::Enabled | BundlingOptions::Minify | BundlingOptions::Autoprefix)
    end

    # Convenience methods for backward compatibility and easier access
    def enabled? : Bool
      @enabled
    end

    def minify? : Bool
      @minify
    end

    def source_maps? : Bool
      @source_maps
    end

    def autoprefix? : Bool
      @autoprefix
    end

    def tree_shake? : Bool
      @tree_shake
    end

    def enabled=(value : Bool)
      @enabled = value
    end

    def minify=(value : Bool)
      @minify = value
    end

    def source_maps=(value : Bool)
      @source_maps = value
    end

    def autoprefix=(value : Bool)
      @autoprefix = value
    end

    def tree_shake=(value : Bool)
      @tree_shake = value
    end
  end

  class CSSBundle
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property name : String = ""

    @[YAML::Field(emit_null: true)]
    property files : Array(String) = [] of String

    @[YAML::Field(emit_null: true)]
    property output : String = ""

    @[YAML::Field(emit_null: true)]
    property order : Int32 = 0

    def initialize(@name : String, @files : Array(String), @output : String, @order = 0)
    end
  end

  class JSBundle
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property name : String = ""

    @[YAML::Field(emit_null: true)]
    property files : Array(String) = [] of String

    @[YAML::Field(emit_null: true)]
    property output : String = ""

    @[YAML::Field(emit_null: true)]
    property order : Int32 = 0

    @[YAML::Field(emit_null: true)]
    property type : String = "application/javascript"

    def initialize(@name : String, @files : Array(String), @output : String, @order = 0, @type = "application/javascript")
    end
  end

  class Config
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property title : String = "Lapis Site"

    @[YAML::Field(emit_null: true)]
    property baseurl : String = ""

    @[YAML::Field(emit_null: true)]
    property description : String = "A site built with Lapis"

    @[YAML::Field(emit_null: true)]
    property author : String = "Site Author"

    @[YAML::Field(emit_null: true)]
    property theme : String = "default"

    @[YAML::Field(emit_null: true)]
    property output_dir : String = "public"

    @[YAML::Field(emit_null: true)]
    property content_dir : String = "content"

    @[YAML::Field(emit_null: true)]
    property layouts_dir : String = "layouts"

    @[YAML::Field(emit_null: true)]
    property static_dir : String = "static"

    @[YAML::Field(emit_null: true)]
    property root_dir : String = "."

    @[YAML::Field(emit_null: true)]
    property theme_dir : String = "themes/default"

    @[YAML::Field(emit_null: true)]
    property build_config : BuildConfig = BuildConfig.new

    @[YAML::Field(emit_null: true)]
    property live_reload_config : LiveReloadConfig = LiveReloadConfig.new

    @[YAML::Field(emit_null: true)]
    property bundling_config : BundlingConfig = BundlingConfig.new

    @[YAML::Field(emit_null: true)]
    property content_type_config : ContentTypeConfig = ContentTypeConfig.new

    @[YAML::Field(emit_null: true)]
    property plugins : Hash(String, YAML::Any) = {} of String => YAML::Any

    @[YAML::Field(emit_null: true)]
    property debug : Bool = false

    @[YAML::Field(emit_null: true)]
    property log_file : String = "lapis.log"

    @[YAML::Field(emit_null: true)]
    property log_level : String = "info"

    @[YAML::Field(emit_null: true)]
    property port : Int32 = 3000

    @[YAML::Field(emit_null: true)]
    property host : String = "localhost"

    @[YAML::Field(emit_null: true)]
    property permalink : String = "/:year/:month/:day/:title/"

    def initialize
    end

    def output_formats : OutputFormatManager
      @output_formats ||= OutputFormatManager.new
    end

    def markdown_config : MarkdownConfig
      @markdown_config ||= MarkdownConfig.new(
        syntax_highlighting: true,
        toc: true,
        smart_quotes: true,
        footnotes: true,
        tables: true
      )
    end

    def self.load(path : String = "config.yml") : Config
      Logger.info("Loading configuration", path: path)

      if File.exists?(path)
        Logger.debug("Config file found", path: path)
        begin
          content = File.read(path)
          Logger.debug("Config file content length", length: content.size.to_s)
          yaml_data = YAML.parse(content).as_h
          config = from_yaml(content)
          config.validate

          # Load output formats from YAML data
          config.output_formats.load_from_config(yaml_data.transform_keys(&.to_s))

          Logger.info("Configuration loaded successfully",
            path: path,
            incremental: config.build_config.incremental?,
            parallel: config.build_config.parallel?,
            cache_dir: config.build_config.cache_dir,
            theme: config.theme)

          # Debug: Show raw config values
          Logger.debug("Raw config values",
            build_incremental: config.build_config.incremental?,
            build_parallel: config.build_config.parallel?,
            build_max_workers: config.build_config.max_workers)
          config
        rescue ex : YAML::ParseException
          raise ConfigError.new("Failed to parse config file: #{ex.message}")
        rescue ex
          Logger.error("Failed to load config file",
            path: path,
            error: ex.message)
          raise ex
        end
      else
        Logger.warn("Config file not found, using defaults", path: path)
        config = new
        Logger.info("Using default configuration",
          incremental: config.build_config.incremental?,
          parallel: config.build_config.parallel?,
          cache_dir: config.build_config.cache_dir,
          theme: config.theme)
        config
      end
    end

    def inspect(io : IO) : Nil
      io << "Config(title: #{@title}, theme: #{@theme}, output_dir: #{@output_dir}, incremental: #{@build_config.incremental?})"
    end

    def validate
      if @output_dir.empty?
        @output_dir = "public"
      end

      if @build_config.cache_dir.empty?
        @build_config.cache_dir = ".lapis_cache"
      end

      if @theme_dir.empty?
        @theme_dir = "themes/default"
      end

      if @content_dir.empty?
        @content_dir = "content"
      end

      if @layouts_dir.empty?
        @layouts_dir = "layouts"
      end

      if @static_dir.empty?
        @static_dir = "static"
      end

      if @root_dir.empty?
        @root_dir = "."
      end

      if @port == 0
        @port = 3000
      end

      # Validate URLs
      validate_urls!
    end

    def validate_urls! : Nil
      if !baseurl.empty?
        begin
          uri = URI.parse(baseurl)
          raise "Invalid base URL: #{baseurl}" if uri.opaque?
          raise "Base URL must have a scheme" if uri.scheme.nil?
        rescue ex
          raise "Configuration error: #{ex.message}"
        end
      end
    end
  end

  class MarkdownConfig
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property syntax_highlighting : Bool = true

    @[YAML::Field(emit_null: true)]
    property toc : Bool = true

    @[YAML::Field(emit_null: true)]
    property smart_quotes : Bool = true

    @[YAML::Field(emit_null: true)]
    property footnotes : Bool = true

    @[YAML::Field(emit_null: true)]
    property tables : Bool = true

    def initialize(@syntax_highlighting = true, @toc = true, @smart_quotes = true, @footnotes = true, @tables = true)
    end
  end
end
