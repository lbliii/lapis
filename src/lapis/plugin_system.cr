require "yaml"
require "log"
require "./logger"
require "./exceptions"
require "./config"

module Lapis
  # NamedTuple type definitions for plugin configuration
  alias PluginConfigStructure = NamedTuple(
    enabled: Bool?,
    options: Hash(String, String)?)

  # Plugin lifecycle events
  enum PluginEvent
    BeforeBuild
    AfterContentLoad
    BeforePageRender
    AfterPageRender
    AfterBuild
    BeforeAssetProcess
    AfterAssetProcess
  end

  # Plugin interface
  abstract class Plugin
    property name : String
    property version : String
    property config : Hash(String, YAML::Any)

    def initialize(@name : String, @version : String = "1.0.0", @config : Hash(String, YAML::Any) = {} of String => YAML::Any)
    end

    # Plugin lifecycle methods
    abstract def on_before_build(generator : Generator) : Nil
    abstract def on_after_content_load(generator : Generator, content : Array(Content)) : Nil
    abstract def on_before_page_render(generator : Generator, content : Content) : Nil
    abstract def on_after_page_render(generator : Generator, content : Content, rendered : String) : Nil
    abstract def on_after_build(generator : Generator) : Nil
    abstract def on_before_asset_process(generator : Generator, asset_path : String) : Nil
    abstract def on_after_asset_process(generator : Generator, asset_path : String, output_path : String) : Nil

    # Helper methods for common plugin operations
    protected def log_info(message : String, **kwargs)
      Logger.info("[#{@name}] #{message}", **kwargs)
    end

    protected def log_debug(message : String, **kwargs)
      Logger.debug("[#{@name}] #{message}", **kwargs)
    end

    protected def log_warn(message : String, **kwargs)
      Logger.warn("[#{@name}] #{message}", **kwargs)
    end

    protected def log_error(message : String, **kwargs)
      Logger.error("[#{@name}] #{message}", **kwargs)
    end
  end

  # Plugin manager for loading and managing plugins
  class PluginManager
    property plugins : Array(Plugin) = [] of Plugin
    property config : Config
    property plugin_dir : String

    def initialize(@config : Config)
      @plugin_dir = File.join(@config.root_dir, "plugins")
      load_plugins
    end

    def register_plugin(plugin : Plugin)
      @plugins << plugin
      Logger.info("Registered plugin", name: plugin.name, version: plugin.version)
    end

    def emit_event(event : PluginEvent, generator : Generator, **kwargs)
      Logger.debug("Emitting plugin event",
        event: event.to_s,
        plugin_count: @plugins.size)

      @plugins.each do |plugin|
        begin
          Logger.debug("Processing plugin event",
            plugin: plugin.name,
            event: event.to_s)

          case event
          when .before_build?
            plugin.on_before_build(generator)
          when .after_content_load?
            content = kwargs[:content]?
            if content && content.is_a?(YAML::Any) && content.as_a?
              plugin.on_after_content_load(generator, content.as_a.map { |c| c.as(Content) })
            end
          when .before_page_render?
            content = kwargs[:content]?
            plugin.on_before_page_render(generator, content) if content && content.is_a?(Content)
          when .after_page_render?
            content = kwargs[:content]?
            rendered = kwargs[:rendered]?
            plugin.on_after_page_render(generator, content, rendered) if content && rendered && content.is_a?(Content)
          when .after_build?
            plugin.on_after_build(generator)
          when .before_asset_process?
            asset_path = kwargs[:asset_path]?
            plugin.on_before_asset_process(generator, asset_path) if asset_path
          when .after_asset_process?
            asset_path = kwargs[:asset_path]?
            output_path = kwargs[:output_path]?
            plugin.on_after_asset_process(generator, asset_path, output_path) if asset_path && output_path
          end
        rescue ex
          Logger.error("Plugin event failed",
            plugin: plugin.name,
            event: event.to_s,
            error: ex.message,
            error_class: ex.class.name)
          # Continue with other plugins
        end
      end
    end

    def get_plugin(name : String) : Plugin?
      @plugins.find { |p| p.name == name }
    end

    def plugin_enabled?(name : String) : Bool
      plugin = get_plugin(name)
      return false unless plugin

      # Check if plugin is enabled in config
      config_key = "plugins.#{name}.enabled"
      plugin.config[config_key]?.try(&.as_bool?) || true
    end

    def plugin_config(name : String) : Hash(String, YAML::Any)
      plugin = get_plugin(name)
      return {} of String => YAML::Any unless plugin

      plugin.config
    end

    private def load_plugins
      return unless Dir.exists?(@plugin_dir)

      # Load plugins from directory
      Dir.glob(File.join(@plugin_dir, "*.cr")).each do |plugin_file|
        load_plugin_from_file(plugin_file)
      end

      # Load plugins from config
      load_plugins_from_config
    end

    private def load_plugin_from_file(plugin_file : String)
      # This would require dynamic loading in a real implementation
      # For now, we'll just log that we found a plugin file
      plugin_name = File.basename(plugin_file, ".cr")
      Logger.debug("Found plugin file", file: plugin_file, name: plugin_name)
    rescue ex
      Logger.error("Failed to load plugin", file: plugin_file, error: ex.message)
    end

    private def load_plugins_from_config
      # Load built-in plugins based on config
      load_builtin_plugins
    end

    # Enhanced NamedTuple-based plugin configuration conversion
    private def load_builtin_plugins
      # SEO Plugin with type-safe configuration
      if seo_config = @config.plugins["seo"]?
        plugin_config = convert_yaml_to_plugin_config(seo_config.as_h)
        register_plugin(SEOPlugin.new(plugin_config))
      end

      # Analytics Plugin with type-safe configuration
      if analytics_config = @config.plugins["analytics"]?
        plugin_config = convert_yaml_to_plugin_config(analytics_config.as_h)
        register_plugin(AnalyticsPlugin.new(plugin_config))
      end

      # Sitemap Plugin with type-safe configuration
      if sitemap_config = @config.plugins["sitemap"]?
        plugin_config = convert_yaml_to_plugin_config(sitemap_config.as_h)
        register_plugin(SitemapPlugin.new(plugin_config))
      end
    end

    # Enhanced conversion using NamedTuple.from for type safety
    private def convert_yaml_to_plugin_config(yaml_hash : Hash(YAML::Any, YAML::Any)) : PluginConfigStructure
      # Use NamedTuple.from for automatic type casting
      PluginConfigStructure.from(yaml_hash.transform_values(&.raw))
    end

    # Legacy method for backward compatibility
    private def convert_yaml_hash(yaml_hash : Hash(YAML::Any, YAML::Any)) : Hash(String, YAML::Any)
      result = Hash(String, YAML::Any).new
      yaml_hash.each do |key, value|
        result[key.to_s] = value
      end
      result
    end
  end

  # Built-in SEO Plugin with enhanced NamedTuple support
  class SEOPlugin < Plugin
    def initialize(config : Hash(String, YAML::Any) | PluginConfigStructure)
      # Convert NamedTuple to Hash if needed for backward compatibility
      config_hash = case config
                    when Hash(String, YAML::Any)
                      config
                    when PluginConfigStructure
                      convert_named_tuple_to_hash(config)
                    else
                      raise ArgumentError.new("Invalid config type")
                    end
      super("seo", "1.0.0", config_hash)
    end

    private def convert_named_tuple_to_hash(config_tuple : PluginConfigStructure) : Hash(String, YAML::Any)
      result = Hash(String, YAML::Any).new
      config_tuple.each do |key, value|
        result[key.to_s] = YAML::Any.new(value)
      end
      result
    end

    def on_before_build(generator : Generator) : Nil
      log_info("Initializing SEO plugin")
    end

    def on_after_content_load(generator : Generator, content : Array(Content)) : Nil
      log_debug("Processing #{content.size} content items for SEO")
    end

    def on_before_page_render(generator : Generator, content : Content) : Nil
      # Add SEO meta tags to content
      add_seo_meta_tags(content)
    end

    def on_after_page_render(generator : Generator, content : Content, rendered : String) : Nil
      # Inject SEO enhancements
      enhanced = inject_seo_enhancements(rendered, content)
      # Note: This would need to be handled differently in a real implementation
      # as we can't modify the rendered string after the fact
    end

    def on_after_build(generator : Generator) : Nil
      generate_sitemap(generator)
      generate_robots_txt(generator)
    end

    def on_before_asset_process(generator : Generator, asset_path : String) : Nil
      # No action needed
    end

    def on_after_asset_process(generator : Generator, asset_path : String, output_path : String) : Nil
      # No action needed
    end

    private def add_seo_meta_tags(content : Content)
      # Add default meta tags if not present
      unless content.frontmatter["description"]?
        content.frontmatter["description"] = YAML::Any.new(content.excerpt || content.content[0..150] + "...")
      end

      unless content.frontmatter["keywords"]?
        # Extract keywords from content
        keywords = extract_keywords(content.content)
        content.frontmatter["keywords"] = YAML::Any.new(keywords.join(", "))
      end
    end

    private def extract_keywords(content : String) : Array(String)
      # Simple keyword extraction
      words = content.downcase.gsub(/[^a-z\s]/, " ").split(/\s+/)
      word_freq = Hash(String, Int32).new(0)

      words.each do |word|
        next if word.size < 3
        word_freq[word] += 1
      end

      # Return top 10 most frequent words
      word_freq.to_a.sort_by { |_, freq| -freq }[0..9].map(&.[0])
    end

    private def inject_seo_enhancements(rendered : String, content : Content) : String
      # Add structured data, meta tags, etc.
      rendered
    end

    private def generate_sitemap(generator : Generator)
      log_info("Generating sitemap")
      # TODO: Implement sitemap generation
    end

    private def generate_robots_txt(generator : Generator)
      log_info("Generating robots.txt")
      # TODO: Implement robots.txt generation
    end
  end

  # Built-in Analytics Plugin
  # Built-in Analytics Plugin with enhanced NamedTuple support
  class AnalyticsPlugin < Plugin
    def initialize(config : Hash(String, YAML::Any) | PluginConfigStructure)
      # Convert NamedTuple to Hash if needed for backward compatibility
      config_hash = case config
                    when Hash(String, YAML::Any)
                      config
                    when PluginConfigStructure
                      convert_named_tuple_to_hash(config)
                    else
                      raise ArgumentError.new("Invalid config type")
                    end
      super("analytics", "1.0.0", config_hash)
    end

    private def convert_named_tuple_to_hash(config_tuple : PluginConfigStructure) : Hash(String, YAML::Any)
      result = Hash(String, YAML::Any).new
      config_tuple.each do |key, value|
        result[key.to_s] = YAML::Any.new(value)
      end
      result
    end

    def on_before_build(generator : Generator) : Nil
      log_info("Initializing Analytics plugin")
    end

    def on_after_content_load(generator : Generator, content : Array(Content)) : Nil
      # No action needed
    end

    def on_before_page_render(generator : Generator, content : Content) : Nil
      # No action needed
    end

    def on_after_page_render(generator : Generator, content : Content, rendered : String) : Nil
      # Inject analytics code
      inject_analytics_code(rendered, content)
    end

    def on_after_build(generator : Generator) : Nil
      log_info("Analytics plugin completed")
    end

    def on_before_asset_process(generator : Generator, asset_path : String) : Nil
      # No action needed
    end

    def on_after_asset_process(generator : Generator, asset_path : String, output_path : String) : Nil
      # No action needed
    end

    private def inject_analytics_code(rendered : String, content : Content)
      # Inject Google Analytics, Plausible, etc.
      # This would need to be handled in the template system
    end
  end

  # Built-in Sitemap Plugin
  # Built-in Sitemap Plugin with enhanced NamedTuple support
  class SitemapPlugin < Plugin
    def initialize(config : Hash(String, YAML::Any) | PluginConfigStructure)
      # Convert NamedTuple to Hash if needed for backward compatibility
      config_hash = case config
                    when Hash(String, YAML::Any)
                      config
                    when PluginConfigStructure
                      convert_named_tuple_to_hash(config)
                    else
                      raise ArgumentError.new("Invalid config type")
                    end
      super("sitemap", "1.0.0", config_hash)
    end

    private def convert_named_tuple_to_hash(config_tuple : PluginConfigStructure) : Hash(String, YAML::Any)
      result = Hash(String, YAML::Any).new
      config_tuple.each do |key, value|
        result[key.to_s] = YAML::Any.new(value)
      end
      result
    end

    def on_before_build(generator : Generator) : Nil
      log_info("Initializing Sitemap plugin")
    end

    def on_after_content_load(generator : Generator, content : Array(Content)) : Nil
      # No action needed
    end

    def on_before_page_render(generator : Generator, content : Content) : Nil
      # No action needed
    end

    def on_after_page_render(generator : Generator, content : Content, rendered : String) : Nil
      # No action needed
    end

    def on_after_build(generator : Generator) : Nil
      generate_sitemap(generator)
    end

    def on_before_asset_process(generator : Generator, asset_path : String) : Nil
      # No action needed
    end

    def on_after_asset_process(generator : Generator, asset_path : String, output_path : String) : Nil
      # No action needed
    end

    private def generate_sitemap(generator : Generator)
      log_info("Generating XML sitemap")
      # TODO: Implement XML sitemap generation
    end
  end
end
