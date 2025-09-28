require "yaml"
require "log"
require "./logger"
require "./exceptions"
require "./config"

module Lapis
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
      @plugins.each do |plugin|
        begin
          case event
          when .before_build?
            plugin.on_before_build(generator)
          when .after_content_load?
            content = kwargs[:content]?
            plugin.on_after_content_load(generator, content) if content
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
          Logger.error("Plugin error", plugin: plugin.name, event: event.to_s, error: ex.message)
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
      begin
        # This would require dynamic loading in a real implementation
        # For now, we'll just log that we found a plugin file
        plugin_name = File.basename(plugin_file, ".cr")
        Logger.debug("Found plugin file", file: plugin_file, name: plugin_name)
      rescue ex
        Logger.error("Failed to load plugin", file: plugin_file, error: ex.message)
      end
    end

    private def load_plugins_from_config
      # Load built-in plugins based on config
      load_builtin_plugins
    end

    private def load_builtin_plugins
      # SEO Plugin
      if seo_config = @config.plugins["seo"]?
        register_plugin(SEOPlugin.new(convert_yaml_hash(seo_config.as_h)))
      end
      
      # Analytics Plugin
      if analytics_config = @config.plugins["analytics"]?
        register_plugin(AnalyticsPlugin.new(convert_yaml_hash(analytics_config.as_h)))
      end
      
      # Sitemap Plugin
      if sitemap_config = @config.plugins["sitemap"]?
        register_plugin(SitemapPlugin.new(convert_yaml_hash(sitemap_config.as_h)))
      end
    end

    private def convert_yaml_hash(yaml_hash : Hash(YAML::Any, YAML::Any)) : Hash(String, YAML::Any)
      result = Hash(String, YAML::Any).new
      yaml_hash.each do |key, value|
        result[key.to_s] = value
      end
      result
    end
  end

  # Built-in SEO Plugin
  class SEOPlugin < Plugin
    def initialize(config : Hash(String, YAML::Any))
      super("seo", "1.0.0", config)
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
        content.frontmatter["description"] = content.excerpt || content.content[0..150] + "..."
      end
      
      unless content.frontmatter["keywords"]?
        # Extract keywords from content
        keywords = extract_keywords(content.content)
        content.frontmatter["keywords"] = keywords.join(", ")
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
  class AnalyticsPlugin < Plugin
    def initialize(config : Hash(String, YAML::Any))
      super("analytics", "1.0.0", config)
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
  class SitemapPlugin < Plugin
    def initialize(config : Hash(String, YAML::Any))
      super("sitemap", "1.0.0", config)
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
