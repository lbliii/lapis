require "./content"
require "yaml"

module Lapis
  class ContentCollections
    getter collections : Hash(String, Collection)
    getter site_content : Array(Content)

    def initialize(@site_content : Array(Content), config : Hash(String, YAML::Any) = {} of String => YAML::Any)
      @collections = {} of String => Collection
      initialize_default_collections
      initialize_custom_collections(config)
    end

    def get_collection(name : String) : Collection?
      @collections[name]?
    end

    def where(collection_name : String, **filters) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      filtered_content = collection.content

      filters.each do |key, value|
        filtered_content = filter_by_property(filtered_content, key.to_s, value)
      end

      filtered_content
    end

    def sort_by(collection_name : String, property : String, reverse : Bool = false) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      sorted = collection.content.sort do |a, b|
        a_value = get_property_value(a, property)
        b_value = get_property_value(b, property)

        case {a_value, b_value}
        when {Time, Time}
          a_value.as(Time) <=> b_value.as(Time)
        when {String, String}
          a_value.as(String) <=> b_value.as(String)
        when {Number, Number}
          a_value.as(Number) <=> b_value.as(Number)
        else
          a_value.to_s <=> b_value.to_s
        end
      end

      reverse ? sorted.reverse : sorted
    end

    def limit(collection_name : String, count : Int32) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      collection.content.first(count)
    end

    def group_by(collection_name : String, property : String) : Hash(String, Array(Content))
      collection = get_collection(collection_name)
      return {} of String => Array(Content) unless collection

      grouped = {} of String => Array(Content)

      collection.content.each do |content|
        value = get_property_value(content, property)
        key = value.to_s

        grouped[key] ||= [] of Content
        grouped[key] << content
      end

      grouped
    end

    def tag_cloud(collection_name : String = "posts") : Hash(String, Int32)
      collection = get_collection(collection_name)
      return {} of String => Int32 unless collection

      tag_counts = {} of String => Int32

      collection.content.each do |content|
        tags = extract_tags(content)
        tags.each do |tag|
          tag_counts[tag] = tag_counts.fetch(tag, 0) + 1
        end
      end

      tag_counts
    end

    def recent(collection_name : String, count : Int32 = 5) : Array(Content)
      sort_by(collection_name, "date", reverse: true).first(count)
    end

    private def initialize_default_collections
      # Posts collection - all content in posts section
      posts = @site_content.select { |c| c.section == "posts" && c.kind.single? }
      @collections["posts"] = Collection.new("posts", posts)

      # Pages collection - all single pages not in posts
      pages = @site_content.select { |c| c.section != "posts" && c.kind.single? }
      @collections["pages"] = Collection.new("pages", pages)

      # All collection - all content
      @collections["all"] = Collection.new("all", @site_content)

      # Sections collection - all section pages
      sections = @site_content.select(&.kind.section?)
      @collections["sections"] = Collection.new("sections", sections)
    end

    private def initialize_custom_collections(config : Hash(String, YAML::Any))
      collections_config = config["collections"]?
      return unless collections_config

      case collections_config
      when Hash
        collections_config.each do |name, collection_config|
          next unless collection_config.is_a?(Hash)

          collection_content = build_custom_collection(collection_config)
          @collections[name] = Collection.new(name, collection_content)
        end
      end
    end

    private def build_custom_collection(config : Hash) : Array(Content)
      filtered_content = @site_content.dup

      # Apply filters from config
      if section = config["section"]?
        section_name = section.as_s
        filtered_content = filtered_content.select { |c| c.section == section_name }
      end

      if kind = config["kind"]?
        kind_name = kind.as_s
        filtered_content = filtered_content.select do |c|
          case kind_name
          when "single"   then c.kind.single?
          when "list"     then c.kind.list?
          when "section"  then c.kind.section?
          when "taxonomy" then c.kind.taxonomy?
          when "term"     then c.kind.term?
          when "home"     then c.kind.home?
          else                 false
          end
        end
      end

      if tags = config["tags"]?
        required_tags = case tags
                        when Array  then tags.map(&.as_s)
                        when String then [tags.as_s]
                        else             [] of String
                        end

        filtered_content = filtered_content.select do |c|
          content_tags = extract_tags(c)
          required_tags.any? { |tag| content_tags.includes?(tag) }
        end
      end

      filtered_content
    end

    private def filter_by_property(content : Array(Content), property : String, value) : Array(Content)
      content.select do |c|
        property_value = get_property_value(c, property)
        matches_value?(property_value, value)
      end
    end

    private def get_property_value(content : Content, property : String)
      case property
      when "title"      then content.title
      when "date"       then content.date
      when "section"    then content.section
      when "kind"       then content.kind.to_s.downcase
      when "url"        then content.url
      when "tags"       then extract_tags(content)
      when "categories" then extract_categories(content)
      else
        # Check frontmatter
        content.frontmatter[property]?.try(&.raw)
      end
    end

    private def matches_value?(property_value, target_value) : Bool
      case {property_value, target_value}
      when {Array, String}
        property_value.as(Array).any? { |v| v.to_s == target_value.to_s }
      when {String, String}
        property_value.as(String) == target_value.to_s
      when {Time, String}
        property_value.as(Time).to_s("%Y-%m-%d") == target_value.to_s
      else
        property_value.to_s == target_value.to_s
      end
    end

    private def extract_tags(content : Content) : Array(String)
      if tags = content.frontmatter["tags"]?
        case tags
        when Array  then tags.map(&.as_s)
        when String then tags.as_s.split(",").map(&.strip)
        else             [] of String
        end
      else
        [] of String
      end
    end

    private def extract_categories(content : Content) : Array(String)
      if categories = content.frontmatter["categories"]?
        case categories
        when Array  then categories.map(&.as_s)
        when String then categories.as_s.split(",").map(&.strip)
        else             [] of String
        end
      else
        [] of String
      end
    end
  end

  class Collection
    getter name : String
    getter content : Array(Content)

    def initialize(@name : String, @content : Array(Content))
    end

    def size : Int32
      @content.size
    end

    def empty? : Bool
      @content.empty?
    end

    def first(count : Int32) : Array(Content)
      @content.first(count)
    end

    def last(count : Int32) : Array(Content)
      @content.last(count)
    end

    def [](index : Int32) : Content?
      @content[index]?
    end

    def each(&block : Content ->)
      @content.each(&block)
    end
  end
end
