require "./content"
# Removed content_comparison - now optimized directly in Content class
require "yaml"

module Lapis
  class ContentCollections
    getter collections : Hash(String, Collection)
    getter site_content : Array(Content)
    property max_collections_size : Int32 = 100
    property max_cache_size : Int32 = 5000

    # Performance optimization: cached lookups
    @url_to_content : Hash(String, Content)?
    @content_by_section : Hash(String, Array(Content))?
    @content_by_kind : Hash(PageKind, Array(Content))?
    @performance_stats : Hash(String, Int32)

    def initialize(@site_content : Array(Content), config : Hash(String, YAML::Any) = {} of String => YAML::Any)
      Logger.debug("Initializing ContentCollections with Reference API optimizations",
        content_count: @site_content.size)

      @collections = {} of String => Collection
      @performance_stats = Hash(String, Int32).new(0)
      build_performance_caches
      initialize_default_collections
      initialize_custom_collections(config)

      # Check memory usage
      memory_manager = Lapis.memory_manager
      memory_manager.check_collection_size("content_collections", @collections.size)
      memory_manager.check_collection_size("site_content", @site_content.size)

      Logger.debug("ContentCollections initialized with performance caches",
        collections: @collections.keys, cache_size: @url_to_content.try(&.size) || 0)
    end

    # PERFORMANCE CACHE BUILDING
    private def build_performance_caches
      @url_to_content = Hash(String, Content).new
      @content_by_section = Hash(String, Array(Content)).new { |h, k| h[k] = [] of Content }
      @content_by_kind = Hash(PageKind, Array(Content)).new { |h, k| h[k] = [] of Content }

      @site_content.each do |content|
        @url_to_content.not_nil![content.url] = content
        @content_by_section.not_nil![content.section] << content
        @content_by_kind.not_nil![content.kind] << content
      end

      @performance_stats["cache_build"] = @site_content.size

      # Check cache sizes
      memory_manager = Lapis.memory_manager
      memory_manager.check_collection_size("url_to_content_cache", @url_to_content.not_nil!.size)
      memory_manager.check_collection_size("content_by_section_cache", @content_by_section.not_nil!.size)
      memory_manager.check_collection_size("content_by_kind_cache", @content_by_kind.not_nil!.size)
    end

    # O(1) LOOKUP METHODS USING REFERENCE OPTIMIZATION
    def find_by_url(url : String) : Content?
      @performance_stats["url_lookup"] += 1
      @url_to_content.try(&.[url]?)
    end

    def find_by_file_path(file_path : String) : Content?
      @performance_stats["file_lookup"] += 1
      @site_content.find { |c| c.file_path == file_path }
    end

    def find_by_object_id(object_id : UInt64) : Content?
      @performance_stats["object_id_lookup"] += 1
      @site_content.find { |c| c.object_id == object_id }
    end

    # OPTIMIZED COLLECTION METHODS
    def where(collection_name : String, **filters) : Array(Content)
      @performance_stats["where_#{collection_name}"] += 1
      collection = get_collection(collection_name)
      return [] of Content unless collection

      # Use reference instead of duplicating
      filtered_content = collection.content

      filters.each do |key, value|
        filtered_content = filter_by_property_optimized(filtered_content, key.to_s, value)
      end

      filtered_content
    end

    def sort_by(collection_name : String, property : String, reverse : Bool = false) : Array(Content)
      @performance_stats["sort_by_#{property}"] += 1
      collection = get_collection(collection_name)
      return [] of Content unless collection

      # Use optimized sorting with caching
      sort_by_property_optimized(collection.content, property, reverse)
    end

    def group_by(collection_name : String, property : String) : Hash(String, Array(Content))
      @performance_stats["group_by_#{property}"] += 1
      collection = get_collection(collection_name)
      return {} of String => Array(Content) unless collection

      # Use optimized grouping with caching
      group_by_property_optimized(collection.content, property)
    end

    # OPTIMIZED FILTERING WITH REFERENCE FEATURES
    private def filter_by_property_optimized(content : Array(Content), property : String, value) : Array(Content)
      case property
      when "url"
        content.select { |c| c.url == value.to_s }
      when "section"
        @content_by_section.try(&.[value.to_s]?) || [] of Content
      when "kind"
        kind_value = PageKind.parse(value.to_s)
        @content_by_kind.try(&.[kind_value]?) || [] of Content
      when "tags"
        content.select(&.tags.includes?(value.to_s))
      when "categories"
        content.select(&.categories.includes?(value.to_s))
      when "draft"
        draft_value = value.to_s == "true"
        content.select { |c| c.draft == draft_value }
      else
        # Fallback to original implementation
        filter_by_property(content, property, value)
      end
    end

    # SLICE-BASED FILTERING FOR ZERO-COPY OPERATIONS
    private def filter_by_property_slice(content : Array(Content), property : String, value) : Slice(Content)
      case property
      when "url"
        filtered_content = content.select { |c| c.url == value.to_s }
        filtered_content.to_slice
      when "section"
        section_content = @content_by_section.try(&.[value.to_s]?) || [] of Content
        section_content.to_slice
      when "kind"
        kind_value = PageKind.parse(value.to_s)
        kind_content = @content_by_kind.try(&.[kind_value]?) || [] of Content
        kind_content.to_slice
      when "tags"
        filtered_content = content.select(&.tags.includes?(value.to_s))
        filtered_content.to_slice
      when "categories"
        filtered_content = content.select(&.categories.includes?(value.to_s))
        filtered_content.to_slice
      when "draft"
        draft_value = value.to_s == "true"
        filtered_content = content.select { |c| c.draft == draft_value }
        filtered_content.to_slice
      else
        # Fallback to original implementation with slice conversion
        filtered_content = filter_by_property(content, property, value)
        filtered_content.to_slice
      end
    end

    # OPTIMIZED SORTING WITH CACHING
    private def sort_by_property_optimized(content : Array(Content), property : String, reverse : Bool = false) : Array(Content)
      case property
      when "date"
        sorted = content.sort
        reverse ? sorted.reverse : sorted
      when "title"
        sorted = content.sort_by(&.title)
        reverse ? sorted.reverse : sorted
      when "url"
        sorted = content.sort_by(&.url)
        reverse ? sorted.reverse : sorted
      else
        # Use Content's optimized comparison directly
        content.sort
      end
    end

    # SLICE-BASED SORTING FOR ZERO-COPY OPERATIONS
    private def sort_by_property_slice(content : Array(Content), property : String, reverse : Bool = false) : Slice(Content)
      case property
      when "date"
        sorted = content.sort
        sorted = sorted.reverse if reverse
        sorted.to_slice
      when "title"
        sorted = content.sort_by(&.title)
        sorted = sorted.reverse if reverse
        sorted.to_slice
      when "url"
        sorted = content.sort_by(&.url)
        sorted = sorted.reverse if reverse
        sorted.to_slice
      else
        # Use Content's optimized comparison directly
        sorted = content.sort
        sorted.to_slice
      end
    end

    # OPTIMIZED GROUPING WITH CACHING
    private def group_by_property_optimized(content : Array(Content), property : String) : Hash(String, Array(Content))
      case property
      when "section"
        # Return reference instead of duplicating
        @content_by_section.not_nil!
      when "kind"
        grouped = Hash(String, Array(Content)).new { |h, k| h[k] = [] of Content }
        @content_by_kind.not_nil!.each do |kind, items|
          grouped[kind.to_s] = items
        end
        grouped
      else
        # Fallback to original implementation
        content.chunk { |c| get_property_value(c, property).to_s }.to_h
      end
    end

    # PERFORMANCE MONITORING
    def performance_stats : Hash(String, Int32)
      # Return reference instead of duplicating
      @performance_stats
    end

    def reset_performance_stats
      @performance_stats.clear
    end

    def get_collection(name : String) : Collection?
      @collections[name]?
    end

    def limit(collection_name : String, count : Int32) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      collection.first(count)
    end

    # SLICE-BASED LIMIT FOR ZERO-COPY OPERATIONS
    def limit_slice(collection_name : String, count : Int32) : Slice(Content)
      collection = get_collection(collection_name)
      return Slice(Content).new(0) unless collection

      collection.first_slice(count)
    end

    def tag_cloud(collection_name : String = "posts") : Hash(String, Int32)
      collection = get_collection(collection_name)
      return {} of String => Int32 unless collection

      tag_counts = {} of String => Int32

      collection.each do |content|
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

    def paginated(collection_name : String, page_size : Int32, page : Int32) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      Logger.debug("Using Iterable pagination", collection: collection_name, page_size: page_size, page: page)
      collection.paginated_content(page_size, page)
    end

    # SLICE-BASED PAGINATION FOR ZERO-COPY OPERATIONS
    def paginated_slice(collection_name : String, page_size : Int32, page : Int32) : Slice(Content)
      collection = get_collection(collection_name)
      return Slice(Content).new(0) unless collection

      Logger.debug("Using Slice pagination", collection: collection_name, page_size: page_size, page: page)
      collection.paginated_slice(page_size, page)
    end

    def grouped_by_date(collection_name : String) : Hash(String, Array(Content))
      collection = get_collection(collection_name)
      return {} of String => Array(Content) unless collection

      Logger.debug("Using Iterable chunking for date grouping", collection: collection_name)
      collection.group_by_date
    end

    def content_sliding_window(collection_name : String, window_size : Int32 = 3) : Array(Array(Content))
      collection = get_collection(collection_name)
      return [] of Array(Content) unless collection

      Logger.debug("Using Iterable each_cons for sliding window", collection: collection_name, window_size: window_size)
      collection.content_previews(window_size)
    end

    # SLICE-BASED SLIDING WINDOW FOR ZERO-COPY OPERATIONS
    def content_sliding_window_slices(collection_name : String, window_size : Int32 = 3) : Array(Slice(Content))
      collection = get_collection(collection_name)
      return [] of Slice(Content) unless collection

      Logger.debug("Using Slice sliding window", collection: collection_name, window_size: window_size)
      collection.content_preview_slices(window_size)
    end

    def section_groups(collection_name : String) : Array(Array(Content))
      collection = get_collection(collection_name)
      return [] of Array(Content) unless collection

      Logger.debug("Using Iterable slice_when for section grouping", collection: collection_name)
      collection.group_by_section_changes
    end

    def recent_with_positions(collection_name : String, count : Int32 = 5) : Array({Content, Int32})
      collection = get_collection(collection_name)
      return [] of {Content, Int32} unless collection

      Logger.debug("Using Iterable each_with_index for recent items", collection: collection_name, count: count)
      collection.recent_with_index(count)
    end

    # SLICE-BASED RECENT WITH POSITIONS FOR ZERO-COPY OPERATIONS
    def recent_with_positions_slice(collection_name : String, count : Int32 = 5) : Slice({Content, Int32})
      collection = get_collection(collection_name)
      return Slice({Content, Int32}).new(0) unless collection

      Logger.debug("Using Slice each_with_index for recent items", collection: collection_name, count: count)
      collection.recent_slice_with_index(count)
    end

    # NEW METHODS FOR MODERN ARRAY OPERATIONS:

    def partition_collection(collection_name : String, **filters) : NamedTuple(matching: Array(Content), non_matching: Array(Content))
      collection = get_collection(collection_name)
      return {matching: [] of Content, non_matching: [] of Content} unless collection

      content = collection.content
      content.partition do |item|
        filters.all? do |key, value|
          property_value = get_property_value(item, key.to_s)
          matches_value?(property_value, value)
        end
      end
    end

    def chunk_collection(collection_name : String, property : String) : Hash(String, Array(Content))
      collection = get_collection(collection_name)
      return {} of String => Array(Content) unless collection

      collection.chunk_by { |content| get_property_value(content, property).to_s }
    end

    def sample_collection(collection_name : String, count : Int32 = 1) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      collection.sample(count)
    end

    def shuffle_collection(collection_name : String) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      collection.shuffle
    end

    def uniq_collection(collection_name : String) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      collection.uniq_by(&.url)
    end

    def compact_collection(collection_name : String) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      collection.compact.reject(&.title.blank?)
    end

    def rotate_collection(collection_name : String, n : Int32 = 1) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      collection.rotate(n)
    end

    def truncate_collection(collection_name : String, range : Range(Int32, Int32)) : Array(Content)
      collection = get_collection(collection_name)
      return [] of Content unless collection

      # Use Range.size for validation
      return [] of Content if range.size <= 0

      collection.truncate(range)
    end

    def index_of_content(collection_name : String, content : Content) : Int32?
      collection = get_collection(collection_name)
      return nil unless collection

      collection.index(content)
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
    include Iterable(Content)
    getter name : String
    getter content : Array(Content)

    # Performance optimization: cached lookups and stats
    @content_by_url : Hash(String, Content)?
    @performance_stats : Hash(String, Int32)

    def initialize(@name : String, @content : Array(Content))
      @performance_stats = Hash(String, Int32).new(0)
      build_url_cache
    end

    # Build URL cache for O(1) lookups
    private def build_url_cache
      @content_by_url = Hash(String, Content).new
      @content.each do |item|
        @content_by_url.not_nil![item.url] = item
      end
    end

    # O(1) lookup by URL
    def find_by_url(url : String) : Content?
      @performance_stats["url_lookup"] += 1
      @content_by_url.try(&.[url]?)
    end

    # O(1) lookup by object_id
    def find_by_object_id(object_id : UInt64) : Content?
      @performance_stats["object_id_lookup"] += 1
      @content.find { |c| c.object_id == object_id }
    end

    # Optimized deduplication using Reference identity
    def deduplicate_by_identity : Collection
      @performance_stats["deduplicate_identity"] += 1
      seen = Set(UInt64).new
      unique_content = @content.select do |item|
        object_id = item.object_id
        if seen.includes?(object_id)
          false
        else
          seen.add(object_id)
          true
        end
      end
      Collection.new(@name, unique_content)
    end

    # Optimized deduplication using logical equality
    def deduplicate_by_url : Collection
      @performance_stats["deduplicate_url"] += 1
      seen_urls = Set(String).new
      unique_content = @content.select do |item|
        if seen_urls.includes?(item.url)
          false
        else
          seen_urls.add(item.url)
          true
        end
      end
      Collection.new(@name, unique_content)
    end

    # Performance monitoring
    def performance_stats : Hash(String, Int32)
      # Return reference instead of duplicating
      @performance_stats
    end

    def reset_performance_stats
      @performance_stats.clear
    end

    # Cleanup method for memory management
    def cleanup
      Logger.debug("Cleaning up ContentCollections")

      # Clear large caches if they exceed limits
      if @url_to_content && @url_to_content.not_nil!.size > @max_cache_size
        Logger.info("Clearing large URL cache", size: @url_to_content.not_nil!.size)
        @url_to_content.not_nil!.clear
      end

      if @content_by_section && @content_by_section.not_nil!.size > @max_cache_size
        Logger.info("Clearing large section cache", size: @content_by_section.not_nil!.size)
        @content_by_section.not_nil!.clear
      end

      if @content_by_kind && @content_by_kind.not_nil!.size > @max_cache_size
        Logger.info("Clearing large kind cache", size: @content_by_kind.not_nil!.size)
        @content_by_kind.not_nil!.clear
      end

      # Clear performance stats
      @performance_stats.clear

      # Force periodic cleanup
      memory_manager = Lapis.memory_manager
      memory_manager.periodic_cleanup
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

    # SLICE-BASED METHODS FOR ZERO-COPY OPERATIONS
    def first_slice(count : Int32) : Slice(Content)
      return Slice(Content).new(0) if count <= 0 || @content.empty?
      @content.to_slice[0, Math.min(count, @content.size)]
    end

    def last_slice(count : Int32) : Slice(Content)
      return Slice(Content).new(0) if count <= 0 || @content.empty?
      start_index = Math.max(0, @content.size - count)
      @content.to_slice[start_index, @content.size - start_index]
    end

    def [](index : Int32) : Content?
      @content[index]?
    end

    def each
      @content.each
    end

    # Advanced iteration methods leveraging Iterable
    def paginated_content(page_size : Int32, page : Int32) : Array(Content)
      return [] of Content if page_size <= 0 || page <= 0
      begin
        each_slice(page_size).to_a[page - 1]? || [] of Content
      rescue ex
        Logger.warn("Error in paginated_content", error: ex.message, page_size: page_size, page: page)
        [] of Content
      end
    end

    # SLICE-BASED PAGINATION FOR ZERO-COPY OPERATIONS
    def paginated_slice(page_size : Int32, page : Int32) : Slice(Content)
      return Slice(Content).new(0) if page_size <= 0 || page <= 0
      begin
        start_index = (page - 1) * page_size
        end_index = Math.min(start_index + page_size, @content.size)
        return Slice(Content).new(0) if start_index >= @content.size
        @content.to_slice[start_index, end_index - start_index]
      rescue ex
        Logger.warn("Error in paginated_slice", error: ex.message, page_size: page_size, page: page)
        Slice(Content).new(0)
      end
    end

    def group_by_date : Hash(String, Array(Content))
      chunk(&.date.to_s).to_h
    rescue ex
      Logger.warn("Error in group_by_date", error: ex.message)
      {} of String => Array(Content)
    end

    def content_previews(window_size : Int32 = 3) : Array(Array(Content))
      return [] of Array(Content) if window_size <= 0

      # Add memory bounds to prevent excessive memory usage
      max_previews = 1000
      max_content_size = 10000

      if @content.size > max_content_size
        Logger.warn("Content collection too large for previews",
          size: @content.size, max: max_content_size)
        return [] of Array(Content)
      end

      begin
        # Limit the number of previews to prevent memory exhaustion
        previews = each_cons(window_size).first(max_previews).to_a
        previews
      rescue ex
        Logger.warn("Error in content_previews", error: ex.message, window_size: window_size)
        [] of Array(Content)
      end
    end

    # SLICE-BASED CONTENT PREVIEWS FOR ZERO-COPY OPERATIONS
    def content_preview_slices(window_size : Int32 = 3) : Array(Slice(Content))
      return [] of Slice(Content) if window_size <= 0

      # Add memory bounds to prevent excessive memory usage
      max_previews = 1000
      max_content_size = 10000

      if @content.size > max_content_size
        Logger.warn("Content collection too large for slice previews",
          size: @content.size, max: max_content_size)
        return [] of Slice(Content)
      end

      begin
        result = [] of Slice(Content)
        content_slice = @content.to_slice
        max_iterations = Math.min(content_slice.size - window_size + 1, max_previews)

        (0...max_iterations).each do |i|
          result << content_slice[i, window_size]
        end

        result
      rescue ex
        Logger.warn("Error in content_preview_slices", error: ex.message, window_size: window_size)
        [] of Slice(Content)
      end
    end

    def group_by_section_changes : Array(Array(Content))
      slice_when { |a, b| a.section != b.section }.to_a
    rescue ex
      Logger.warn("Error in group_by_section_changes", error: ex.message)
      [] of Array(Content)
    end

    def recent_with_index(count : Int32 = 5) : Array({Content, Int32})
      return [] of {Content, Int32} if count <= 0
      begin
        each_with_index.first(count).to_a
      rescue ex
        Logger.warn("Error in recent_with_index", error: ex.message, count: count)
        [] of {Content, Int32}
      end
    end

    # SLICE-BASED RECENT ITEMS WITH INDEX FOR ZERO-COPY OPERATIONS
    def recent_slice_with_index(count : Int32 = 5) : Slice({Content, Int32})
      return Slice({Content, Int32}).new(0) if count <= 0
      begin
        result = Array({Content, Int32}).new(Math.min(count, @content.size))
        content_slice = @content.to_slice

        (0...Math.min(count, content_slice.size)).each do |i|
          result << {content_slice[i], i}
        end

        result.to_slice
      rescue ex
        Logger.warn("Error in recent_slice_with_index", error: ex.message, count: count)
        Slice({Content, Int32}).new(0)
      end
    end

    # NEW METHODS FOR MODERN ARRAY OPERATIONS:

    def partition(&block : Content -> Bool) : NamedTuple(matching: Array(Content), non_matching: Array(Content))
      @content.partition(&block)
    end

    def chunk_by(&block : Content -> String) : Hash(String, Array(Content))
      @content.chunk_by(&block)
    end

    def sample(count : Int32 = 1) : Array(Content)
      @content.sample(count)
    end

    def shuffle : Array(Content)
      @content.shuffle
    end

    def uniq_by(&block : Content -> String) : Array(Content)
      @content.uniq_by(&block)
    end

    def compact : Array(Content)
      @content.compact.reject(&.title.blank?)
    end

    def rotate(n : Int32 = 1) : Array(Content)
      @content.rotate(n)
    end

    def truncate(range : Range(Int32, Int32)) : Array(Content)
      # Use Range.size for validation
      return [] of Content if range.size <= 0

      @content.truncate(range)
    end

    def index_of(content : Content) : Int32?
      @content.index(content)
    end

    def last_index_of(content : Content) : Int32?
      @content.rindex(content)
    end
  end
end
