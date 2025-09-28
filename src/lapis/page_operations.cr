require "./content"
require "./content_comparison"

module Lapis
  class PageOperations
    getter content : Content
    getter site_content : Array(Content)

    def initialize(@content : Content, @site_content : Array(Content))
    end

    def summary(length : Int32 = 160) : String
      if summary_from_frontmatter = @content.frontmatter["summary"]?
        return summary_from_frontmatter.as_s
      end

      if description = @content.frontmatter["description"]?
        return description.as_s
      end

      # Extract first paragraph or truncate content
      plain_content = @content.body.gsub(/<[^>]*>/, "").strip
      sentences = plain_content.split(/[.!?]+/)

      summary = ""
      sentences.each do |sentence|
        next_summary = summary.empty? ? sentence.strip : "#{summary} #{sentence.strip}"
        break if next_summary.size > length
        summary = next_summary
      end

      summary.empty? ? plain_content[0..length]? || "" : summary
    end

    def reading_time : Int32
      words = word_count
      # Average reading speed: 200 words per minute
      (words / 200.0).ceil.to_i.clamp(1..)
    end

    def word_count : Int32
      plain_content = @content.body.gsub(/<[^>]*>/, "").strip
      plain_content.split(/\s+/).size
    end

    def next_in_section : Content?
      section_pages = @site_content.select { |c| c.section == @content.section && c.kind.single? }
        .sort

      current_index = section_pages.index(@content)
      return nil unless current_index

      section_pages[current_index - 1]? if current_index > 0
    end

    def prev_in_section : Content?
      section_pages = @site_content.select { |c| c.section == @content.section && c.kind.single? }
        .sort

      current_index = section_pages.index(@content)
      return nil unless current_index

      section_pages[current_index + 1]?
    end

    def parent : Content?
      return nil if @content.section.empty?

      # Look for section's _index.md
      section_index_path = File.join(@content.section, "_index")
      @site_content.find(&.url.starts_with?(section_index_path))
    end

    def ancestors : Array(Content)
      ancestors = [] of Content
      path_parts = @content.section.split("/").reject(&.empty?)

      path_parts.each_with_index do |_, index|
        ancestor_path = path_parts[0..index].join("/")
        ancestor_index_path = File.join(ancestor_path, "_index")

        if ancestor = @site_content.find(&.url.starts_with?(ancestor_index_path))
          ancestors << ancestor
        end
      end

      ancestors
    end

    def children : Array(Content)
      return [] of Content unless @content.kind.section? || @content.kind.list?

      section_path = @content.section.empty? ? "" : "#{@content.section}/"
      @site_content.select do |c|
        c.section.starts_with?(section_path) &&
          c.section != @content.section &&
          c.section.count("/") == @content.section.count("/") + 1
      end
    end

    def related(limit : Int32 = 5) : Array(Content)
      return [] of Content if @site_content.size <= 1

      # Get content tags and categories for similarity matching
      content_tags = tags_array
      content_categories = categories_array

      scored_content = @site_content.compact_map do |other_content|
        next if other_content == @content
        next unless other_content.kind.single?

        score = calculate_similarity_score(other_content, content_tags, content_categories)
        {content: other_content, score: score} if score > 0
      end

      scored_content.sort_by { |item| -item[:score] }
        .first(limit)
        .map { |item| item[:content] }
    end

    private def calculate_similarity_score(other : Content, content_tags : Array(String), content_categories : Array(String)) : Int32
      score = 0

      # Tag similarity (higher weight)
      other_tags = extract_tags(other)
      common_tags = content_tags & other_tags
      score += common_tags.size * 3

      # Category similarity (medium weight)
      other_categories = extract_categories(other)
      common_categories = content_categories & other_categories
      score += common_categories.size * 2

      # Section similarity (lower weight)
      if other.section == @content.section
        score += 1
      end

      score
    end

    private def tags_array : Array(String)
      extract_tags(@content)
    end

    private def categories_array : Array(String)
      extract_categories(@content)
    end

    private def extract_tags(content : Content) : Array(String)
      if tags = content.frontmatter["tags"]?
        case tags
        when Array
          tags.map(&.as_s)
        when String
          tags.as_s.split(",").map(&.strip)
        else
          [] of String
        end
      else
        [] of String
      end
    end

    private def extract_categories(content : Content) : Array(String)
      if categories = content.frontmatter["categories"]?
        case categories
        when Array
          categories.map(&.as_s)
        when String
          categories.as_s.split(",").map(&.strip)
        else
          [] of String
        end
      else
        [] of String
      end
    end

    def url : String
      @content.url
    end

    def title : String
      @content.title
    end

    def date : Time?
      @content.date
    end

    def section : String
      @content.section
    end

    def kind : PageKind
      @content.kind
    end

    def tags : Array(String)
      tags_array
    end

    def categories : Array(String)
      categories_array
    end

    def content_html : String
      @content.body
    end

    def params : Hash(String, YAML::Any)
      @content.frontmatter
    end
  end
end
