require "./content"
require "./page_operations"
require "./site"

module Lapis
  # Enhanced Page object - advanced page methods
  class Page
    getter content : Content
    getter site : Site
    getter operations : PageOperations

    def initialize(@content : Content, @site : Site)
      @operations = PageOperations.new(@content, @site.pages)
    end

    # BASIC PAGE PROPERTIES

    def title : String
      @content.title
    end

    def content_html : String
      @content.content
    end

    def summary : String
      @operations.summary
    end

    def truncated : Bool
      # Check if summary was truncated from content
      @operations.summary.size < plain_content.size
    end

    def description : String
      @content.description || summary
    end

    def keywords : Array(String)
      tags + categories
    end

    def url : String
      @content.url
    end

    def permalink : String
      @site.base_url.chomp("/") + @content.url
    end

    def rel_permalink : String
      @content.url
    end

    # METADATA

    def date : Time?
      @content.date
    end

    def publish_date : Time?
      @content.frontmatter["publishDate"]?.try { |d| Time.parse(d.as_s, "%Y-%m-%d", Time::Location::UTC) } || date
    end

    def lastmod : Time?
      @content.frontmatter["lastmod"]?.try { |d| Time.parse(d.as_s, "%Y-%m-%d", Time::Location::UTC) } || date
    end

    def expiry_date : Time?
      @content.frontmatter["expiryDate"]?.try { |d| Time.parse(d.as_s, "%Y-%m-%d", Time::Location::UTC) }
    end

    def draft : Bool
      @content.draft
    end

    def build_draft : Bool
      ENV.fetch("LAPIS_BUILD_DRAFTS", "false") == "true"
    end

    def future : Bool
      if pd = publish_date
        pd > Time.utc
      else
        false
      end
    end

    def expired : Bool
      if ed = expiry_date
        ed < Time.utc
      else
        false
      end
    end

    # TAXONOMIES

    def tags : Array(String)
      @operations.tags
    end

    def categories : Array(String)
      @operations.categories
    end

    def params : Hash(String, YAML::Any)
      @content.frontmatter
    end

    def param(key : String)
      params[key]?
    end

    # CONTENT METRICS

    def word_count : Int32
      @operations.word_count
    end

    def fuzzy_word_count : Int32
      # Approximate word count - same as word_count for now
      word_count
    end

    def reading_time : Int32
      @operations.reading_time
    end

    def plain : String
      plain_content
    end

    def plain_words : Array(String)
      plain_content.split(/\s+/).reject(&.empty?)
    end

    def content_without_summary : String
      full_content = content_html
      summary_text = summary

      if full_content.includes?(summary_text)
        full_content.sub(summary_text, "").strip
      else
        full_content
      end
    end

    # PAGE RELATIONSHIPS

    def next : Content?
      @operations.next_in_section
    end

    def prev : Content?
      @operations.prev_in_section
    end

    def next_in_section : Content?
      next
    end

    def prev_in_section : Content?
      prev
    end

    def parent : Content?
      @operations.parent
    end

    def ancestors : Array(Content)
      @operations.ancestors
    end

    def children : Array(Content)
      @operations.children
    end

    def siblings : Array(Content)
      return [] of Content unless parent_page = parent

      parent_page_operations = PageOperations.new(parent_page, @site.pages)
      parent_page_operations.children.reject { |c| c == @content }
    end

    def related : Array(Content)
      @operations.related
    end

    # PAGE HIERARCHY

    def section : String
      @operations.section
    end

    def current_section : Content?
      @site.pages.find { |p| p.section == section && p.kind.section? }
    end

    def first_section : Content?
      return nil if section.empty?

      top_section = section.split("/").first
      @site.pages.find { |p| p.section == top_section && p.kind.section? }
    end

    def in_section(section_name : String) : Bool
      section == section_name || section.starts_with?("#{section_name}/")
    end

    def ancestor?(other : Content) : Bool
      other.section.starts_with?(section + "/")
    end

    def descendant?(other : Content) : Bool
      section.starts_with?(other.section + "/")
    end

    # PAGE KIND

    def kind : String
      @content.kind.to_s.downcase
    end

    def home? : Bool
      @content.kind.home?
    end

    def page? : Bool
      @content.kind.single?
    end

    def section? : Bool
      @content.kind.section?
    end

    def type : String
      @content.frontmatter["type"]?.try(&.as_s) || section
    end

    def layout : String
      @content.frontmatter["layout"]?.try(&.as_s) || "single"
    end

    # FILE INFORMATION

    def file : Hash(String, String)
      {
        "path"      => @content.file_path,
        "dir"       => File.dirname(@content.file_path),
        "filename"  => File.basename(@content.file_path),
        "extension" => File.extname(@content.file_path),
        "base_name" => File.basename(@content.file_path, File.extname(@content.file_path)),
      }
    end

    def file_path : String
      @content.file_path
    end

    # LANGUAGE AND INTERNATIONALIZATION

    def lang : String
      @content.frontmatter["lang"]?.try(&.as_s) || @site.language_code
    end

    def language : Hash(String, String)
      {
        "lang"          => lang,
        "language_name" => @content.frontmatter["languageName"]?.try(&.as_s) || "English",
        "weight"        => @content.frontmatter["languageWeight"]?.try(&.as_s) || "1",
      }
    end

    # CONTENT FORMATS

    def markup : String
      case File.extname(@content.file_path).downcase
      when ".md", ".markdown"   then "markdown"
      when ".html", ".htm"      then "html"
      when ".org"               then "org"
      when ".asciidoc", ".adoc" then "asciidoc"
      else                           "markdown"
      end
    end

    def table_of_contents : String
      # Simple TOC generation from headers
      headers = content_html.scan(/<h([1-6])[^>]*>(.*?)<\/h[1-6]>/)
      return "" if headers.empty?

      toc = String.build do |str|
        str << %(<nav class="table-of-contents">\n<ul>\n)

        headers.each do |match|
          level = match[1].to_i
          text = match[2].gsub(/<[^>]*>/, "").strip
          id = text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")

          indent = "  " * level
          str << %(#{indent}<li><a href="##{id}">#{text}</a></li>\n)
        end

        str << %(</ul>\n</nav>)
      end

      toc
    end

    def toc : String
      table_of_contents
    end

    # OUTPUT FORMATS

    def output_formats : Array(String)
      ["html", "json", "rss"] # Default formats
    end

    def alternative_output_formats : Array(String)
      output_formats.reject { |f| f == "html" }
    end

    # CUSTOM METHODS

    def excerpt(length : Int32 = 160) : String
      @operations.summary(length)
    end

    def has_shortcode?(name : String) : Bool
      content_html.includes?("{{< #{name}")
    end

    def get_term(taxonomy : String) : Array(String)
      case taxonomy
      when "tags"       then tags
      when "categories" then categories
      else                   [] of String
      end
    end

    def weight : Int32
      @content.frontmatter["weight"]?.try(&.as_i) || 0
    end

    def menu : Hash(String, Hash(String, String))
      menu_config = @content.frontmatter["menu"]?
      return {} of String => Hash(String, String) unless menu_config

      result = {} of String => Hash(String, String)

      case menu_config.raw
      when Hash
        menu_config.as_h.each do |menu_name, menu_data|
          menu_hash = {} of String => String
          if menu_data.raw.is_a?(Hash)
            menu_data.as_h.each do |key, value|
              menu_hash[key] = value.as_s
            end
          end
          result[menu_name] = menu_hash
        end
      end

      result
    end

    def inspect(io : IO) : Nil
      io << "Page(title: #{title}, url: #{url}, kind: #{kind}, date: #{date.try(&.to_s("%Y-%m-%d")) || "nil"})"
    end

    def bundle_type : String
      # Page bundle type (leaf, branch) - simplified for now
      "leaf"
    end

    # Debug property - returns site debug setting
    def debug : Bool
      @site.debug
    end

    # Debug info method for template debugging - returns formatted page information
    def debug_info : String
      String.build do |str|
        str << "# Page Debug Information\n\n"

        # Basic page info
        str << "## Page Properties\n"
        str << "- **Title**: #{title}\n"
        str << "- **URL**: #{url}\n"
        str << "- **Permalink**: #{permalink}\n"
        str << "- **Kind**: #{kind}\n"
        str << "- **Type**: #{type}\n"
        str << "- **Layout**: #{layout}\n"
        str << "- **Section**: #{section}\n"
        str << "- **Weight**: #{weight}\n\n"

        # Content information
        str << "## Content Information\n"
        str << "- **Word Count**: #{word_count}\n"
        str << "- **Reading Time**: #{reading_time} minutes\n"
        str << "- **Markup**: #{markup}\n"
        str << "- **Has TOC**: #{@content.toc}\n"
        str << "- **Description**: #{description}\n\n"

        # Dates
        str << "## Dates\n"
        str << "- **Date**: #{date.try(&.to_s("%Y-%m-%d %H:%M:%S")) || "Not set"}\n"
        str << "- **Publish Date**: #{publish_date.try(&.to_s("%Y-%m-%d %H:%M:%S")) || "Not set"}\n"
        str << "- **Last Modified**: #{lastmod.try(&.to_s("%Y-%m-%d %H:%M:%S")) || "Not set"}\n"
        str << "- **Expiry Date**: #{expiry_date.try(&.to_s("%Y-%m-%d %H:%M:%S")) || "Not set"}\n\n"

        # Status flags
        str << "## Status\n"
        str << "- **Draft**: #{draft}\n"
        str << "- **Future**: #{future}\n"
        str << "- **Expired**: #{expired}\n"
        str << "- **Published**: #{!draft && !future && !expired}\n\n"

        # Taxonomies
        if tags.any? || categories.any?
          str << "## Taxonomies\n"
          if tags.any?
            str << "- **Tags**: #{tags.join(", ")}\n"
          end
          if categories.any?
            str << "- **Categories**: #{categories.join(", ")}\n"
          end
          str << "\n"
        end

        # File information
        str << "## File Information\n"
        str << "- **File Path**: #{file_path}\n"
        str << "- **Directory**: #{file["dir"]}\n"
        str << "- **Filename**: #{file["filename"]}\n"
        str << "- **Extension**: #{file["extension"]}\n"
        str << "- **Base Name**: #{file["base_name"]}\n\n"

        # Relationships
        str << "## Page Relationships\n"
        if parent_page = parent
          str << "- **Parent**: #{parent_page.title} (#{parent_page.url})\n"
        end
        if children.any?
          str << "- **Children**: #{children.size} pages\n"
        end
        if siblings.any?
          str << "- **Siblings**: #{siblings.size} pages\n"
        end
        if next_page = self.next
          str << "- **Next**: #{next_page.title} (#{next_page.url})\n"
        end
        if prev_page = self.prev
          str << "- **Previous**: #{prev_page.title} (#{prev_page.url})\n"
        end
        str << "\n"

        # Frontmatter (limited to avoid overwhelming output)
        str << "## Frontmatter (First 10 items)\n"
        @content.frontmatter.first(10).each do |key, value|
          str << "- **#{key}**: #{value.raw.inspect}\n"
        end
        if @content.frontmatter.size > 10
          str << "- ... and #{@content.frontmatter.size - 10} more items\n"
        end
      end
    end

    private def plain_content : String
      content_html.gsub(/<[^>]*>/, "").strip
    end
  end
end
