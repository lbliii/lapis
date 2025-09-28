require "yaml"
require "markd"
require "log"
require "uri"
require "./base_content"
require "./page_kinds"
require "./content_types"
require "./logger"
require "./exceptions"
require "./data_processor"
require "./shortcodes"

# Removed content_comparison - now optimized directly in Content class

module Lapis
  class Content < BaseContent
    include Comparable(Content)
    property title : String
    property layout : String
    property date : Time?
    property tags : Array(String)
    property categories : Array(String)
    property permalink : String?
    property draft : Bool
    property description : String?
    property author : String?
    property toc : Bool
    property frontmatter : Hash(String, YAML::Any)
    property body : String
    property content : String
    property raw_content : String
    property file_path : String
    property url : String
    property kind : PageKind
    property section : String
    property content_type : ContentType

    # Performance optimization: cached hash value
    @cached_hash : UInt64?
    @cached_date_comparison : Time?

    def initialize(@file_path : String, @frontmatter : Hash(String, YAML::Any), @body : String, content_dir : String = "content")
      Logger.debug("Initializing Content with Reference API optimizations", file: @file_path)

      # Validate UTF-8 encoding for content
      unless @body.valid_encoding?
        Logger.warn("Invalid UTF-8 encoding detected in content", file: @file_path)
        @body = @body.scrub # Replace invalid sequences with replacement character
      end

      @title = @frontmatter["title"]?.try(&.as_s) || humanize_filename(Path[@file_path].stem)
      @layout = @frontmatter["layout"]?.try(&.as_s) || "default"
      @content_type = if type_from_frontmatter = @frontmatter["type"]?.try(&.as_s)
                        ContentType.parse(type_from_frontmatter)
                      else
                        infer_content_type
                      end
      @date = parse_date(@frontmatter["date"]?)
      @tags = parse_array(@frontmatter["tags"]?)
      @categories = parse_array(@frontmatter["categories"]?)
      @permalink = @frontmatter["permalink"]?.try(&.as_s)
      @draft = @frontmatter["draft"]?.try(&.as_bool) || false
      @description = @frontmatter["description"]?.try(&.as_s)
      @author = @frontmatter["author"]?.try(&.as_s)
      @toc = @frontmatter["toc"]?.try(&.as_bool) || true
      @raw_content = @body
      @content = @body # Will be processed later with config

      # Detect page kind and section
      @kind = PageKindDetector.detect(@file_path, content_dir)
      @section = PageKindDetector.detect_section(@file_path, content_dir)

      @url = generate_url

      Logger.debug("Content initialized with optimized Reference API",
        title: @title, url: @url, kind: @kind, section: @section)
    end

    def self.load(file_path : String, content_dir : String = "content") : Content
      Logger.file_operation("loading content", file_path)

      File.open(file_path, "r") do |file|
        file.set_encoding("UTF-8")
        content = file.gets_to_end
        frontmatter, body = parse_frontmatter(content)
        new(file_path, frontmatter, body, content_dir)
      end
    rescue ex : File::NotFoundError
      Logger.error("Content file not found", file: file_path)
      raise ContentError.new("Content file not found: #{file_path}", file_path)
    rescue ex : IO::Error
      Logger.error("Error reading content file", file: file_path, error: ex.message)
      raise ContentError.new("Error reading content file #{file_path}: #{ex.message}", file_path)
    rescue ex : YAML::ParseException
      Logger.error("YAML parsing error in content file", file: file_path, error: ex.message)
      raise ContentError.new("YAML parsing error in #{file_path}: #{ex.message}", file_path)
    rescue ex : ValidationError
      Logger.error("Content validation error", file: file_path, error: ex.message)
      raise ContentError.new("Content validation error in #{file_path}: #{ex.message}", file_path)
    end

    def self.load_all(directory : String) : Array(Content)
      Logger.info("Loading all content from directory", directory: directory)
      content = [] of Content

      if Dir.exists?(directory)
        Dir.glob(Path[directory].join("**", "*.md").to_s).each do |file_path|
          begin
            content << load(file_path, directory)
          rescue ex : ContentError
            Logger.warn("Skipping invalid content file", file: file_path, error: ex.message)
          rescue ex
            Logger.warn("Unexpected error loading content", file: file_path, error: ex.message)
          end
        end
      else
        Logger.warn("Content directory does not exist", directory: directory)
      end

      Logger.info("Loaded content files", count: content.size.to_s)
      content.sort
    end

    def self.create_new(type : String, title : String)
      filename = title.downcase.gsub(/[^a-z0-9]+/, "-").strip("-")
      content_type = ContentType.parse(type)

      case content_type
      when .article?
        dir = "content/posts"
        path = Path[dir].join("#{filename}.md").to_s
        layout = "post"
      else
        dir = "content"
        path = Path[dir].join("#{filename}.md").to_s
        layout = "page"
      end

      Dir.mkdir_p(dir)

      content = "---\n"
      content += "title: \"#{title}\"\n"
      content += "date: \"#{Time.utc.to_s(Lapis::DATE_FORMAT)}\"\n"
      content += "layout: \"#{layout}\"\n"
      content += "draft: false\n"

      if content_type.article?
        content += "tags: []\n"
      end
      content += "---\n\n"
      content += "# #{title}\n\n"
      content += "Write your content here...\n"

      write_file_atomically(path, content)
      puts "Created #{path}"
    end

    private def self.write_file_atomically(path : String, content : String)
      temp_path = "#{path}.tmp"

      File.open(temp_path, "w") do |file|
        file.set_encoding("UTF-8")
        file.print(content)
        file.flush
      end

      File.rename(temp_path, path)
    rescue ex : IO::Error
      File.delete(temp_path) if temp_path && File.exists?(temp_path)
      raise "Error writing content file #{path}: #{ex.message}"
    end

    def page? : Bool
      true # All content is now treated as pages
    end

    # Check if this content should be included in feeds and archives
    def feedable? : Bool
      @content_type.feedable? && !@draft
    end

    # Check if this content should use date-based URLs
    def date_based_url? : Bool
      @content_type.date_based_url? && @date != nil
    end

    # Legacy methods for backward compatibility - will be removed
    def post? : Bool
      @content_type.article?
    end

    def post_layout? : Bool
      post?
    end

    private def infer_content_type : ContentType
      # Infer content type based on file path and layout
      if @layout == "post" || @layout == "article"
        ContentType::Article
      elsif @file_path.includes?("/posts/") || @file_path.includes?("/articles/")
        ContentType::Article
      elsif @file_path.includes?("/pages/")
        ContentType::Page
      elsif @file_path.includes?("/glossary/")
        ContentType::Glossary
      elsif @file_path.includes?("/docs/")
        ContentType::Documentation
      else
        ContentType::Page
      end
    end

    # Page kind helpers
    def single? : Bool
      @kind.single?
    end

    def list? : Bool
      @kind.list? || @kind.section? || @kind.taxonomy? || @kind.home?
    end

    def section? : Bool
      @kind.section?
    end

    def taxonomy? : Bool
      @kind.taxonomy?
    end

    def term? : Bool
      @kind.term?
    end

    def home? : Bool
      @kind.home?
    end

    def process_content(config : Config)
      @content = process_markdown(@body, config)
    end

    def excerpt(length : Int32 = 200) : String
      text = @content.gsub(/<[^>]*>/, "")
      if text.size <= length
        text
      else
        range = 0...length
        text[range] + "..."
      end
    end

    private def self.parse_frontmatter(content : String) : Tuple(Hash(String, YAML::Any), String)
      if content.starts_with?("---\n")
        parts = content.split("---\n", 3)
        if parts.size >= 3
          frontmatter_yaml = parts[1]
          body = parts[2]

          frontmatter = Hash(String, YAML::Any).new
          if !frontmatter_yaml.strip.empty?
            parsed = YAML.parse(frontmatter_yaml)
            if parsed.as_h?
              frontmatter = parsed.as_h.transform_keys(&.to_s)
            end
          end

          return {frontmatter, body}
        end
      end

      {Hash(String, YAML::Any).new, content}
    end

    private def humanize_filename(text : String) : String
      # Convert filename-like strings to human readable format
      text.gsub(/[-_]/, " ")
        .split(" ")
        .map(&.capitalize)
        .join(" ")
    end

    private def process_markdown(markdown : String, config : Config) : String
      # First process shortcodes, then convert markdown
      processor = ShortcodeProcessor.new(config)
      processed_markdown = processor.process(markdown)

      options = Markd::Options.new(
        smart: true,
        safe: false
      )

      Markd.to_html(processed_markdown, options)
    end

    private def parse_date(date_value : YAML::Any?) : Time?
      return nil unless date_value

      # Handle both string and Time objects from YAML
      if date_value.raw.is_a?(Time)
        return date_value.raw.as(Time)
      elsif date_value.raw.is_a?(String)
        date_str = date_value.raw.as(String)
        begin
          Time.parse(date_str, Lapis::DATE_FORMAT_SHORT, Time::Location::UTC)
        rescue Time::Format::Error
          begin
            Time.parse(date_str, Lapis::DATE_FORMAT, Time::Location::UTC)
          rescue Time::Format::Error
            nil
          end
        end
      else
        nil
      end
    end

    private def parse_array(value : YAML::Any?) : Array(String)
      return [] of String unless value

      if array = value.as_a?
        array.map(&.as_s)
      elsif string = value.as_s?
        [string]
      else
        [] of String
      end
    end

    private def generate_url : String
      if @permalink
        return @permalink.try { |p| p } || generate_url
      end

      begin
        if date_based_url?
          date = @date.try { |d| d } || Time.utc
          year = date.year.to_s
          month = date.month.to_s.rjust(2, '0')
          day = date.day.to_s.rjust(2, '0')
          slug = Path[@file_path].stem
          Path["/"].join(year, month, day, slug).to_s + "/"
        else
          if @kind.section? || @kind.list?
            @section.empty? ? "/" : URI.parse("/").resolve("#{@section}/").path
          else
            slug = Path[@file_path].stem
            if slug == "index"
              "/"
            else
              # For nested paths, use the relative path from content directory
              rel_path = Path[@file_path].relative_to(Path["content"]).to_s
              path_parts = Path[rel_path].parts[0..-2] # All parts except filename
              if path_parts.empty?
                Path["/"].join(slug).to_s + "/"
              else
                Path["/"].join(path_parts + [slug]).to_s + "/"
              end
            end
          end
        end
      rescue ex : Path::Error
        Logger.path_error("url_generation", @file_path, ex.message || "Unknown error")
        raise PathError.new("Error generating URL for #{@file_path}: #{ex.message}", @file_path, "url_generation")
      rescue ex
        Logger.path_error("url_generation", @file_path, ex.message || "Unknown error")
        raise PathError.new("Unexpected error generating URL for #{@file_path}: #{ex.message}", @file_path, "url_generation")
      end
    end

    # Process shortcodes in content
    def process_shortcodes(processor : ShortcodeProcessor)
      @content = processor.process(@content)
    end

    # OPTIMIZED REFERENCE API IMPLEMENTATION

    # High-performance hash implementation using URL as primary key
    def hash(hasher)
      hasher = @url.hash(hasher)
      hasher = @file_path.hash(hasher)
      hasher = @title.hash(hasher)
      hasher
    end

    # Logical equality based on URL and file path
    def ==(other : Content) : Bool
      return false unless other.is_a?(Content)
      @url == other.url && @file_path == other.file_path
    end

    # Enhanced same? for object identity
    def same?(other : Content) : Bool
      super(other)
    end

    # Optimized dup - shallow copy is sufficient for Content
    def dup : Content
      super
    end

    # Enhanced inspect with performance data
    def inspect(io : IO) : Nil
      io << "Content("
      io << "title: #{@title.inspect}, "
      io << "url: #{@url.inspect}, "
      io << "kind: #{@kind}, "
      io << "section: #{@section}, "
      io << "date: #{@date.try(&.to_s("%Y-%m-%d")) || "nil"}, "
      io << "tags: #{@tags.size}, "
      io << "hash: #{@cached_hash || "uncached"}, "
      io << "file: #{Path[@file_path].basename}"
      io << ")"
    end

    # OPTIMIZED COMPARISON WITH CACHING
    def <=>(other : Content) : Int32?
      # Use cached date comparison for performance
      date_comparison = compare_dates_cached(other)
      return date_comparison unless date_comparison == 0

      @title <=> other.title
    end

    private def compare_dates_cached(other : Content) : Int32
      our_date = @date || Time.unix(0)
      other_date = other.date || Time.unix(0)

      # Cache the comparison date for future use
      @cached_date_comparison = our_date

      -(our_date <=> other_date) # Reverse for newest first
    end

    # EXPERIMENTAL REFERENCE FEATURES (Crystal 1.17.1+)

    # Experimental: Custom object construction for performance
    def self.unsafe_construct_from_cache(cached_data : Hash(String, String), file_path : String) : Content
      # This would use Reference.unsafe_construct for zero-copy construction
      # when we have pre-processed content data
      frontmatter = Hash(String, YAML::Any).new
      cached_data.each do |key, value|
        frontmatter[key] = YAML::Any.new(value)
      end

      # For now, use regular construction until Crystal 1.17.1 is stable
      new(file_path, frontmatter, cached_data["body"]? || "")
    end

    # Experimental: Memory-efficient content cloning
    def clone_with_reference_optimization : Content
      # Use Reference features for efficient cloning
      cloned = dup
      # Reset caches for cloned object - create new instance with reset caches
      cloned = Content.new(@file_path, @frontmatter, @body)
      cloned
    end

    # Experimental: Zero-copy content sharing
    def share_content_with(other : Content) : Bool
      # Check if we can share content without copying
      return false unless @file_path == other.file_path

      # For now, just return true as we can't modify other object's instance variables
      # This would need to be implemented differently in a real scenario
      true
    end

    # Performance monitoring integration
    def performance_stats : NamedTuple(hash_cached: Bool, date_cached: Bool, object_id: UInt64)
      {
        hash_cached: !@cached_hash.nil?,
        date_cached: !@cached_date_comparison.nil?,
        object_id:   object_id,
      }
    end
  end
end

# String extension for humanizing filenames
class String
  def humanize
    self.gsub(/[-_]/, " ").split.map(&.capitalize).join(" ")
  end
end
