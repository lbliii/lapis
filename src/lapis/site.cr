require "./content"
require "./navigation"
require "./collections"
require "yaml"

module Lapis
  # Site object - global site context
  class Site
    getter config : Config
    getter pages : Array(Content)
    getter menus : Hash(String, Array(MenuItem))
    getter params : Hash(String, YAML::Any)
    getter data : Hash(String, YAML::Any)

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
        "version" => "lapis-0.4.0",
        "generator" => "Lapis Static Site Generator",
        "environment" => ENV["LAPIS_ENV"]? || "production",
        "commit_hash" => "",
        "build_date" => build_date.to_s("%Y-%m-%d %H:%M:%S %Z")
      }
    end

    def generator : String
      generator_info["generator"]
    end

    def version : String
      generator_info["version"]
    end

    # URLS AND PATHS

    def base_url_scheme : String
      uri = URI.parse(@config.baseurl)
      uri.scheme || "https"
    end

    def base_url_host : String
      uri = URI.parse(@config.baseurl)
      uri.host || "localhost"
    end

    def base_url_port : Int32
      uri = URI.parse(@config.baseurl)
      uri.port || (base_url_scheme == "https" ? 443 : 80)
    end

    def base_url_path : String
      uri = URI.parse(@config.baseurl)
      uri.path || "/"
    end

    # SITE-WIDE OPERATIONS

    def is_server : Bool
      ENV["LAPIS_SERVER"]? == "true"
    end

    def is_multihost : Bool
      false # Not implemented yet
    end

    def workspace : String
      Dir.current
    end

    # CUSTOM HELPER METHODS

    def recent_posts(limit : Int32 = 5) : Array(Content)
      @pages.select(&.kind.single?)
        .sort_by { |p| p.date || Time.unix(0) }
        .reverse
        .first(limit)
    end

    def posts_by_year : Hash(Int32, Array(Content))
      grouped = {} of Int32 => Array(Content)
      @pages.select(&.kind.single?).each do |page|
        year = page.date.try(&.year) || 0
        grouped[year] ||= [] of Content
        grouped[year] << page
      end
      grouped
    end

    def posts_by_month : Hash(String, Array(Content))
      grouped = {} of String => Array(Content)
      @pages.select(&.kind.single?).each do |page|
        if date = page.date
          month_key = "#{date.year}-#{date.month.to_s.rjust(2, '0')}"
          grouped[month_key] ||= [] of Content
          grouped[month_key] << page
        end
      end
      grouped
    end

    def tag_cloud : Hash(String, Int32)
      cloud = {} of String => Int32
      @pages.each do |page|
        page.tags.each do |tag|
          cloud[tag] = cloud.fetch(tag, 0) + 1
        end
      end
      cloud
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
      when "title" then page.title
      when "section" then page.section
      when "kind" then page.kind.to_s
      when "url" then page.url
      when "date" then page.date.try(&.to_s("%Y-%m-%d")) || ""
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