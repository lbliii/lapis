require "./content"
require "./collections"

module Lapis
  class ContentQuery
    getter site_content : Array(Content)
    getter collections : ContentCollections

    def initialize(@site_content : Array(Content), @collections : ContentCollections)
    end

    def where(**filters) : QueryBuilder
      QueryBuilder.new(@site_content, @collections).where(**filters)
    end

    def sort_by(property : String, reverse : Bool = false) : QueryBuilder
      QueryBuilder.new(@site_content, @collections).sort_by(property, reverse)
    end

    def limit(count : Int32) : QueryBuilder
      QueryBuilder.new(@site_content, @collections).limit(count)
    end

    def from_collection(name : String) : QueryBuilder
      collection = @collections.get_collection(name)
      content = collection ? collection.content : [] of Content
      QueryBuilder.new(content, @collections)
    end

    def posts : QueryBuilder
      from_collection("posts")
    end

    def pages : QueryBuilder
      from_collection("pages")
    end

    def sections : QueryBuilder
      from_collection("sections")
    end

    def recent(count : Int32 = 5) : Array(Content)
      @site_content.select(&.kind.single?)
        .sort_by { |c| c.date || Time.unix(0) }
        .reverse
        .first(count)
    end

    def by_tag(tag : String) : Array(Content)
      @site_content.select do |content|
        extract_tags(content).includes?(tag)
      end
    end

    def by_category(category : String) : Array(Content)
      @site_content.select do |content|
        extract_categories(content).includes?(category)
      end
    end

    def by_section(section : String) : Array(Content)
      @site_content.select { |c| c.section == section }
    end

    def related_to(content : Content, limit : Int32 = 5) : Array(Content)
      content_tags = extract_tags(content)
      content_categories = extract_categories(content)

      scored_content = @site_content.compact_map do |other_content|
        next if other_content == content
        next unless other_content.kind.single?

        score = calculate_similarity_score(other_content, content_tags, content_categories, content.section)
        {content: other_content, score: score} if score > 0
      end

      scored_content.sort_by { |item| -item[:score] }
        .first(limit)
        .map { |item| item[:content] }
    end

    def tagged_with_any(*tags) : Array(Content)
      tag_strings = tags.map(&.to_s)
      @site_content.select do |content|
        content_tags = extract_tags(content)
        tag_strings.any? { |tag| content_tags.includes?(tag) }
      end
    end

    def tagged_with_all(*tags) : Array(Content)
      tag_strings = tags.map(&.to_s)
      @site_content.select do |content|
        content_tags = extract_tags(content)
        tag_strings.all? { |tag| content_tags.includes?(tag) }
      end
    end

    def search(query : String) : Array(Content)
      query_words = query.downcase.split(/\s+/)

      @site_content.select do |content|
        searchable_text = "#{content.title} #{content.body}".downcase
        query_words.any? { |word| searchable_text.includes?(word) }
      end
    end

    private def calculate_similarity_score(other : Content, content_tags : Array(String), content_categories : Array(String), content_section : String) : Int32
      score = 0

      # Tag similarity (highest weight)
      other_tags = extract_tags(other)
      common_tags = content_tags & other_tags
      score += common_tags.size * 3

      # Category similarity (medium weight)
      other_categories = extract_categories(other)
      common_categories = content_categories & other_categories
      score += common_categories.size * 2

      # Section similarity (lower weight)
      if other.section == content_section
        score += 1
      end

      score
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

  class QueryBuilder
    getter current_content : Array(Content)
    getter collections : ContentCollections

    def initialize(@current_content : Array(Content), @collections : ContentCollections)
    end

    def where(**filters) : QueryBuilder
      filtered = @current_content.select do |content|
        filters.all? do |key, value|
          property_value = get_property_value(content, key.to_s)
          matches_value?(property_value, value)
        end
      end.tap { |result| Logger.debug("Filtered content", count: result.size, filters: filters.keys) }

      QueryBuilder.new(filtered, @collections)
    end

    def sort_by(property : String, reverse : Bool = false) : QueryBuilder
      sorted = @current_content.sort do |a, b|
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
      end.tap { |result| Logger.debug("Sorted content", count: result.size, property: property, reverse: reverse) }

      final_content = reverse ? sorted.reverse : sorted
      QueryBuilder.new(final_content, @collections)
    end

    def limit(count : Int32) : QueryBuilder
      QueryBuilder.new(@current_content.first(count), @collections)
        .tap { |result| Logger.debug("Limited content", count: result.count, limit: count) }
    end

    def first(count : Int32) : Array(Content)
      @current_content.first(count)
    end

    def last(count : Int32) : Array(Content)
      @current_content.last(count)
    end

    def all : Array(Content)
      @current_content
    end

    def count : Int32
      @current_content.size
    end

    def empty? : Bool
      @current_content.empty?
    end

    def group_by(property : String) : Hash(String, Array(Content))
      grouped = {} of String => Array(Content)

      @current_content.each do |content|
        value = get_property_value(content, property)
        key = value.to_s

        grouped[key] ||= [] of Content
        grouped[key] << content
      end

      grouped
    end

    def pluck(property : String) : Array(String)
      @current_content.map do |content|
        get_property_value(content, property).to_s
      end
    end

    def distinct(property : String) : Array(String)
      pluck(property).uniq
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
end
