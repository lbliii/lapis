require "./content"
require "./navigation"
require "./collections"
require "./content_comparison"
require "yaml"
require "uri"

module Lapis
  # Site object - global site context
  class Site
    getter config : Config
    getter pages : Array(Content)
    getter menus : Hash(String, Array(MenuItem))
    getter params : Hash(String, YAML::Any)
    getter data : Hash(String, YAML::Any)
    @parsed_baseurl : URI? = nil

    def initialize(@config : Config, @pages : Array(Content) = [] of Content)
      @menus = {} of String => Array(MenuItem)
      @params = {} of String => YAML::Any
      @data = {} of String => YAML::Any

      load_site_config
      load_menus
      load_data_files
    end

    # BASIC SITE PROPERTIES

    def title : String
      @config.title
    end

    def base_url : String
      @config.baseurl
    end

    def language_code : String
      @params["languageCode"]?.try(&.as_s) || "en"
    end

    def author : Hash(String, String)
      author_config = @params["author"]?
      if author_config && author_config.raw.is_a?(Hash)
        result = {} of String => String
        author_config.as_h.each do |key, value|
          result[key.to_s] = value.as_s
        end
        result
      else
        {"name" => @config.author, "email" => ""}
      end
    end

    def copyright : String
      @params["copyright"]?.try(&.as_s) || ""
    end

    def description : String
      @config.description
    end

    def theme : String
      @config.theme
    end

    def theme_dir : String
      @config.theme_dir
    end

    def layouts_dir : String
      @config.layouts_dir
    end

    def static_dir : String
      @config.static_dir
    end

    def output_dir : String
      @config.output_dir
    end

    def content_dir : String
      @config.content_dir
    end

    def debug : Bool
      @config.debug
    end

    def build_config : BuildConfig
      @config.build_config
    end

    def live_reload_config : LiveReloadConfig
      @config.live_reload_config
    end

    def bundling_config : BundlingConfig
      @config.bundling_config
    end

    # CONTENT COLLECTIONS

    def all_pages : Array(Content)
      @pages
    end

    def regular_pages : Array(Content)
      @pages.select(&.kind.single?)
    end

    def section_pages : Array(Content)
      @pages.select(&.kind.section?)
    end

    def home : Content?
      @pages.find(&.kind.home?)
    end

    # PAGE QUERIES

    def get_page(path : String) : Content?
      @pages.find { |p| p.url == path || p.file_path.includes?(path) }
    end

    def where(field : String, operator : String, value : String) : Array(Content)
      @pages.select do |page|
        page_value = get_page_field(page, field)
        case operator
        when "eq", "="
          page_value == value
        when "ne", "!="
          page_value != value
        when "in"
          page_value.includes?(value)
        when "not in"
          !page_value.includes?(value)
        else
          false
        end
      end
    end

    def where(field : String, value : String) : Array(Content)
      where(field, "eq", value)
    end

    # TAXONOMIES

    def taxonomies : Hash(String, Hash(String, Array(Content)))
      taxonomies = {} of String => Hash(String, Array(Content))

      # Tags taxonomy
      tags = {} of String => Array(Content)
      @pages.each do |page|
        page.tags.each do |tag|
          tags[tag] ||= [] of Content
          tags[tag] << page
        end
      end
      taxonomies["tags"] = tags

      # Categories taxonomy
      categories = {} of String => Array(Content)
      @pages.each do |page|
        page.categories.each do |category|
          categories[category] ||= [] of Content
          categories[category] << page
        end
      end
      taxonomies["categories"] = categories

      taxonomies
    end

    def tags : Hash(String, Array(Content))
      taxonomies["tags"]? || {} of String => Array(Content)
    end

    def categories : Hash(String, Array(Content))
      taxonomies["categories"]? || {} of String => Array(Content)
    end

    # SECTIONS

    def sections : Hash(String, Array(Content))
      sections = {} of String => Array(Content)
      @pages.each do |page|
        next if page.section.empty?
        sections[page.section] ||= [] of Content
        sections[page.section] << page
      end
      sections
    end

    def get_section(name : String) : Array(Content)
      sections[name]? || [] of Content
    end

    # BUILD INFO

    def build_date : Time
      Time.utc
    end

    def generator_info : Hash(String, String)
      {
        "version"     => "lapis-0.4.0",
        "generator"   => "Lapis Static Site Generator",
        "environment" => ENV["LAPIS_ENV"]? || "production",
        "commit_hash" => "",
        "build_date"  => build_date.to_s("%Y-%m-%d %H:%M:%S %Z"),
      }
    end

    def inspect(io : IO) : Nil
      io << "Site(title: #{@config.title}, pages: #{@pages.size}, theme: #{@config.theme}, baseurl: #{@config.baseurl})"
    end

    def version : String
      generator_info["version"]
    end

    # URI COMPONENTS - Proper URI handling
    private def parsed_baseurl : URI
      @parsed_baseurl ||= begin
        parsed = URI.parse(@config.baseurl)
        raise "Invalid base URL: #{@config.baseurl}" if parsed.opaque?
        parsed.normalize
      end
    end

    def base_url_scheme : String
      parsed_baseurl.scheme || "https"
    end

    def base_url_host : String
      parsed_baseurl.host || "localhost"
    end

    def base_url_port : Int32
      parsed_baseurl.port || (base_url_scheme == "https" ? 443 : 80)
    end

    def base_url_path : String
      parsed_baseurl.path || "/"
    end

    def base_url_normalized : String
      parsed_baseurl.to_s
    end

    def resolve_url(path : String) : String
      parsed_baseurl.resolve(path).to_s
    end

    def relativize_url(absolute_url : String) : String
      parsed_baseurl.relativize(absolute_url).to_s
    end

    def validate_base_url : Bool
      uri = URI.parse(@config.baseurl)
      !uri.opaque? && !uri.scheme.nil?
    rescue
      false
    end

    # SITE-WIDE OPERATIONS

    def server? : Bool
      ENV["LAPIS_SERVER"]? == "true"
    end

    def multihost? : Bool
      false # Not implemented yet
    end

    def workspace : String
      Dir.current
    end

    # CUSTOM HELPER METHODS

    def recent_posts(limit : Int32 = 5) : Array(Content)
      @pages.select(&.kind.single?)
        .tap { |posts| Logger.debug("Found single pages", count: posts.size) }
        .sort
        .tap { |sorted| Logger.debug("Sorted by date", first_date: sorted.first?.date.try(&.to_s("%Y-%m-%d"))) }
        .first(limit)
        .tap { |recent| Logger.debug("Recent posts", count: recent.size) }
    end

    def posts_by_year : Hash(Int32, Array(Content))
      @pages.select(&.kind.single?)
        .tap { |posts| Logger.debug("Processing posts by year", count: posts.size) }
        .group_by { |page| page.date.try(&.year) || 0 }
        .tap { |grouped| Logger.debug("Grouped by year", years: grouped.keys.sort) }
    end

    def posts_by_month : Hash(String, Array(Content))
      @pages.select(&.kind.single?)
        .tap { |posts| Logger.debug("Processing posts by month", count: posts.size) }
        .compact_map { |page| page.date.try { |date| {page, "#{date.year}-#{date.month.to_s.rjust(2, '0')}"} } }
        .group_by { |(page, month_key)| month_key }
        .transform_values { |pairs| pairs.map { |(page, _)| page } }
        .tap { |grouped| Logger.debug("Grouped by month", months: grouped.keys.sort) }
    end

    def tag_cloud : Hash(String, Int32)
      @pages.flat_map(&.tags)
        .tap { |tags| Logger.debug("Processing tag cloud", total_tags: tags.size) }
        .tally
        .tap { |cloud| Logger.debug("Tag cloud generated", unique_tags: cloud.size) }
    end

    private def load_site_config
      # Load additional configuration from _config.yml or lapis.yml if it exists
      config_files = ["_config.yml", "lapis.yml", "config.yml"]

      config_files.each do |config_file|
        if File.exists?(config_file)
          begin
            yaml_content = read_site_config_file(config_file)
            yaml_data = YAML.parse(yaml_content)

            if yaml_data.raw.is_a?(Hash)
              yaml_data.as_h.each do |key, value|
                @params[key.to_s] = value
              end
            end
          rescue ex
            # Skip invalid YAML files
          end
          break
        end
      end
    end

    private def load_menus
      # Load menus from config
      if menus_config = @params["menus"]?
        case menus_config.raw
        when Hash
          menus_config.as_h.each do |menu_name, menu_items|
            @menus[menu_name.to_s] = parse_menu_items(menu_items)
          end
        end
      end
    end

    private def parse_menu_items(items) : Array(MenuItem)
      menu_items = [] of MenuItem

      case items.raw
      when Array
        items.as_a.each do |item|
          if item.raw.is_a?(Hash)
            item_hash = item.as_h
            name = item_hash["name"]?.try(&.as_s) || ""
            url = item_hash["url"]?.try(&.as_s) || ""
            weight = item_hash["weight"]?.try(&.as_i) || 0

            next if name.empty? || url.empty?

            menu_items << MenuItem.new(
              name: name,
              url: url,
              weight: weight,
              external: url.starts_with?("http")
            )
          end
        end
      end

      menu_items.sort_by(&.weight)
    end

    private def load_data_files
      # Load data files from data/ directory
      data_dir = "data"
      return unless Dir.exists?(data_dir)

      Dir.glob(File.join(data_dir, "**", "*.yml")).each do |file_path|
        begin
          yaml_content = read_site_config_file(file_path)
          yaml_data = YAML.parse(yaml_content)

          # Create nested structure based on file path
          relative_path = file_path[data_dir.size + 1..]
          key = File.basename(relative_path, ".yml")

          @data[key] = yaml_data
        rescue ex
          # Skip invalid YAML files
        end
      end
    end

    private def get_page_field(page : Content, field : String) : String
      case field
      when "title"   then page.title
      when "section" then page.section
      when "kind"    then page.kind.to_s
      when "url"     then page.url
      when "date"    then page.date.try(&.to_s("%Y-%m-%d")) || ""
      else
        # Check frontmatter
        page.frontmatter[field]?.try(&.as_s) || ""
      end
    end

    private def read_site_config_file(file_path : String) : String
      File.open(file_path, "r") do |file|
        file.set_encoding("UTF-8")
        file.gets_to_end
      end
    rescue ex : File::NotFoundError
      raise "Site config file not found: #{file_path}"
    rescue ex : IO::Error
      raise "Error reading site config file #{file_path}: #{ex.message}"
    end
  end
end
