require "ecr"
require "./base_content"
require "./theme_helpers"
require "./partials"

module Lapis
  class TemplateEngine
    include ThemeHelpers

    property config : Config
    property layouts_dir : String
    property theme_layouts_dir : String

    def initialize(@config : Config)
      @layouts_dir = @config.layouts_dir
      @theme_layouts_dir = File.join(@config.theme_dir, "layouts")
    end

    def render(content : Content, layout : String? = nil, output_format : OutputFormat? = nil) : String
      context = TemplateContext.new(@config, content, output_format)

      # Use page kind-aware template resolution
      if layout
        # Explicit layout specified, use traditional resolution
        render_with_inheritance(layout, context)
      else
        # Use page kind and format-aware resolution
        layout_path = find_layout_by_page_kind_and_format(content, output_format)
        if layout_path
          layout_content = File.read(layout_path)

          # Check if this layout extends another layout
          if extends_match = layout_content.match(/\{\{\s*extends\s+"([^"]+)"\s*\}\}/)
            parent_layout = extends_match[1]
            render_with_parent(layout_content, parent_layout, context)
          else
            # No inheritance, render directly
            process_template(layout_content, context)
          end
        else
          render_default_layout(context)
        end
      end
    end

    # Render content in all configured output formats
    def render_all_formats(content : Content) : Hash(String, String)
      results = Hash(String, String).new
      formats = @config.output_formats.formats_for_kind(content.kind)

      formats.each do |format|
        begin
          rendered = render(content, nil, format)
          results[format.name] = rendered
        rescue ex
          puts "Warning: Failed to render '#{content.file_path}' in #{format.name} format (#{format.extension}): #{ex.message}"
        end
      end

      results
    end

    def render_archive_page(title : String, posts : Array(Content), pagination_html : String = "", layout : String = "archive") : String
      # Create a virtual content object for archive pages
      archive_content = ArchiveContent.new(title, posts, pagination_html)
      context = TemplateContext.new(@config, archive_content)
      
      render_with_inheritance(layout, context)
    end

    private def render_with_inheritance(layout_name : String, context : TemplateContext) : String
      layout_path = find_layout(layout_name)
      
      if layout_path
        layout_content = File.read(layout_path)
        
        # Check if this layout extends another layout
        if extends_match = layout_content.match(/\{\{\s*extends\s+"([^"]+)"\s*\}\}/)
          parent_layout = extends_match[1]
          render_with_parent(layout_content, parent_layout, context)
        else
          # No inheritance, render directly
          process_template(layout_content, context)
        end
      else
        render_default_layout(context)
      end
    end

    private def render_with_parent(child_content : String, parent_layout : String, context : TemplateContext) : String
      parent_path = find_layout(parent_layout)
      return render_default_layout(context) unless parent_path
      
      parent_content = File.read(parent_path)
      
      # Extract blocks from child template
      blocks = extract_blocks(child_content)
      
      # Replace block placeholders in parent with child blocks
      result = parent_content
      blocks.each do |block_name, block_content|
        result = result.gsub(/\{\{\s*block\s+"#{block_name}"\s*\}\}.*?\{\{\s*endblock\s*\}\}/m, block_content)
      end
      
      # Process any remaining default blocks
      result = result.gsub(/\{\{\s*block\s+"([^"]+)"\s*\}\}(.*?)\{\{\s*endblock\s*\}\}/m) do |match|
        block_name = $1
        default_content = $2
        blocks[block_name]? || default_content
      end
      
      process_template(result, context)
    end

    private def extract_blocks(template : String) : Hash(String, String)
      blocks = Hash(String, String).new
      
      template.scan(/\{\{\s*block\s+"([^"]+)"\s*\}\}(.*?)\{\{\s*endblock\s*\}\}/m) do |match|
        block_name = match[1]
        block_content = match[2]
        blocks[block_name] = block_content
      end
      
      blocks
    end

    private def find_layout(layout_name : String, content : Content? = nil) : String?
      # If content is provided, use page kind-aware template resolution
      if content
        return find_layout_by_page_kind(content)
      end

      # Fallback to simple layout resolution
      # Check local layouts first
      local_path = File.join(@layouts_dir, "#{layout_name}.html")
      return local_path if File.exists?(local_path)

      # Check theme layouts
      theme_path = File.join(@theme_layouts_dir, "#{layout_name}.html")
      return theme_path if File.exists?(theme_path)

      nil
    end

    # Hugo-style template lookup order based on page kind and output format
    private def find_layout_by_page_kind_and_format(content : Content, output_format : OutputFormat?) : String?
      candidates = [] of String
      format_suffix = output_format ? ".#{output_format.name}" : ""
      extension = output_format ? output_format.extension : "html"

      case content.kind
      when .single?
        # For single pages: section/single.format.ext -> section/single.ext -> _default/single.format.ext -> _default/single.ext
        unless content.section.empty?
          candidates << File.join(@layouts_dir, content.section, "single#{format_suffix}.#{extension}")
          candidates << File.join(@theme_layouts_dir, content.section, "single#{format_suffix}.#{extension}")
          candidates << File.join(@layouts_dir, content.section, "single.#{extension}")
          candidates << File.join(@theme_layouts_dir, content.section, "single.#{extension}")
        end
        candidates << File.join(@layouts_dir, "_default", "single#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "single#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "single.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "single.#{extension}")

        # Fallback to explicit layout if specified
        if content.layout != "default"
          candidates << File.join(@layouts_dir, "#{content.layout}#{format_suffix}.#{extension}")
          candidates << File.join(@theme_layouts_dir, "#{content.layout}#{format_suffix}.#{extension}")
          candidates << File.join(@layouts_dir, "#{content.layout}.#{extension}")
          candidates << File.join(@theme_layouts_dir, "#{content.layout}.#{extension}")
        end

      when .list?, .section?
        # For list/section pages: section/list.format.ext -> _default/list.format.ext
        unless content.section.empty?
          candidates << File.join(@layouts_dir, content.section, "list#{format_suffix}.#{extension}")
          candidates << File.join(@theme_layouts_dir, content.section, "list#{format_suffix}.#{extension}")
          candidates << File.join(@layouts_dir, content.section, "list.#{extension}")
          candidates << File.join(@theme_layouts_dir, content.section, "list.#{extension}")
        end
        candidates << File.join(@layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "list.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list.#{extension}")

      when .home?
        # For home page: index.format.ext -> _default/home.format.ext -> _default/list.format.ext
        candidates << File.join(@layouts_dir, "index#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "index#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "index.#{extension}")
        candidates << File.join(@theme_layouts_dir, "index.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "home#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "home#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "home.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "home.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "list.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list.#{extension}")

      when .taxonomy?
        # For taxonomy pages: taxonomy.format.ext -> _default/taxonomy.format.ext -> _default/list.format.ext
        candidates << File.join(@layouts_dir, "taxonomy#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "taxonomy#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "taxonomy.#{extension}")
        candidates << File.join(@theme_layouts_dir, "taxonomy.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "taxonomy#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "taxonomy#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "taxonomy.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "taxonomy.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "list.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list.#{extension}")

      when .term?
        # For term pages: term.format.ext -> _default/term.format.ext -> _default/list.format.ext
        candidates << File.join(@layouts_dir, "term#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "term#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "term.#{extension}")
        candidates << File.join(@theme_layouts_dir, "term.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "term#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "term#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "term.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "term.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list#{format_suffix}.#{extension}")
        candidates << File.join(@layouts_dir, "_default", "list.#{extension}")
        candidates << File.join(@theme_layouts_dir, "_default", "list.#{extension}")
      end

      # Find first existing template
      candidates.each do |path|
        if File.exists?(path)
          return path
        end
      end

      nil
    end

    # Backward compatibility method
    private def find_layout_by_page_kind(content : Content) : String?
      find_layout_by_page_kind_and_format(content, nil)
    end

    def render_layout(layout_path : String, content : Content) : String
      layout_content = File.read(layout_path)
      context = TemplateContext.new(@config, content)
      process_template(layout_content, context)
    end

    def render_default_layout(context : TemplateContext) : String
      process_template(default_layout_template, context)
    end

    private def process_template(template : String, context : TemplateContext) : String
      # Process partials first (Hugo-style)
      result = Partials.process_partials(template, context, @config.theme_dir)

      # Process basic variables
      result = result.gsub("{{ title }}", context.content.title)
      result = result.gsub("{{ content }}", context.content.content)
      result = result.gsub("{{ site.title }}", context.site_title)
      result = result.gsub("{{ site.description }}", context.site_description)
      result = result.gsub("{{ site.author }}", context.site_author)
      result = result.gsub("{{ site.baseurl }}", context.site_baseurl)

      # Page kind and section information
      if context.content.is_a?(Content) && (content = context.content.as(Content))
        result = result.gsub("{{ page.kind }}", content.kind.to_s)
        result = result.gsub("{{ page.section }}", content.section)
        result = result.gsub("{{ section }}", content.section)
      end

      # Legacy CSS includes support (will be deprecated)
      result = result.gsub("{{ css_includes }}", context.css_includes)

      # Auto CSS discovery (preferred method)
      result = result.gsub("{{ auto_css }}", Partials.generate_auto_css(context))

      # Date formatting
      if date = context.content.date
        result = result.gsub("{{ date }}", date.to_s(Lapis::DATE_FORMAT_SHORT))
        result = result.gsub("{{ date_formatted }}", date.to_s(Lapis::DATE_FORMAT_HUMAN))
      else
        result = result.gsub("{{ date }}", "")
        result = result.gsub("{{ date_formatted }}", "")
      end

      # Tags and categories
      if context.output_format && context.output_format.not_nil!.name == "json"
        # For JSON format, output proper JSON arrays
        tags_json = context.content.tags.map { |tag| %("#{tag}") }.join(", ")
        result = result.gsub("{{ tags }}", "[#{tags_json}]")

        categories_json = context.content.categories.map { |cat| %("#{cat}") }.join(", ")
        result = result.gsub("{{ categories }}", "[#{categories_json}]")
      else
        # For HTML format, output HTML spans
        tags_html = context.content.tags.map { |tag| %(<span class="tag">#{tag}</span>) }.join(" ")
        result = result.gsub("{{ tags }}", tags_html)

        categories_html = context.content.categories.map { |cat| %(<span class="category">#{cat}</span>) }.join(" ")
        result = result.gsub("{{ categories }}", categories_html)
      end

      # URL
      result = result.gsub("{{ url }}", context.content.url)

      # Description
      result = result.gsub("{{ description }}", context.content.description || context.content.excerpt)

      # Process conditional blocks
      result = process_conditionals(result, context)

      result
    end

    private def process_conditionals(template : String, context : TemplateContext) : String
      result = template

      # Process {{ if date }} blocks
      if context.content.date
        result = result.gsub(/\{\{\s*if\s+date\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m) { $1 }
      else
        result = result.gsub(/\{\{\s*if\s+date\s*\}\}.*?\{\{\s*endif\s*\}\}/m, "")
      end

      # Process {{ if tags }} blocks
      if !context.content.tags.empty?
        result = result.gsub(/\{\{\s*if\s+tags\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m) { $1 }
      else
        result = result.gsub(/\{\{\s*if\s+tags\s*\}\}.*?\{\{\s*endif\s*\}\}/m, "")
      end

      # Process {{ if description }} blocks
      if context.content.description && !context.content.description.not_nil!.empty?
        result = result.gsub(/\{\{\s*if\s+description\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m) { $1 }
      else
        result = result.gsub(/\{\{\s*if\s+description\s*\}\}.*?\{\{\s*endif\s*\}\}/m, "")
      end

      result
    end

    private def default_layout_template : String
      <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{{ title }} - {{ site.title }}</title>
        <meta name="description" content="{{ description }}">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
          }

          header {
            border-bottom: 1px solid #eee;
            padding-bottom: 20px;
            margin-bottom: 30px;
          }

          .site-title {
            font-size: 2em;
            font-weight: bold;
            color: #2c3e50;
            text-decoration: none;
          }

          .site-description {
            color: #666;
            margin-top: 5px;
          }

          .content {
            margin-bottom: 40px;
          }

          .meta {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 20px;
          }

          .tag, .category {
            background: #f8f9fa;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 0.8em;
            margin-right: 5px;
          }

          footer {
            border-top: 1px solid #eee;
            padding-top: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
          }

          h1, h2, h3, h4, h5, h6 {
            color: #2c3e50;
          }

          a {
            color: #3498db;
            text-decoration: none;
          }

          a:hover {
            text-decoration: underline;
          }

          pre {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
          }

          code {
            background: #f8f9fa;
            padding: 2px 4px;
            border-radius: 3px;
          }

          blockquote {
            border-left: 4px solid #3498db;
            margin: 0;
            padding-left: 20px;
            color: #666;
          }
        </style>
      </head>
      <body>
        <header>
          <a href="/" class="site-title">{{ site.title }}</a>
          <div class="site-description">{{ site.description }}</div>
        </header>

        <main>
          <article class="content">
            <h1>{{ title }}</h1>

            <div class="meta">
              {{ date_formatted }}
              {{ tags }}
              {{ categories }}
            </div>

            {{ content }}
          </article>
        </main>

        <footer>
          <p>Built with <a href="https://github.com/lapis-lang/lapis">Lapis</a> static site generator</p>
        </footer>
      </body>
      </html>
      HTML
    end
  end

  class TemplateContext
    include ThemeHelpers

    getter config : Config
    getter content : BaseContent
    getter output_format : OutputFormat?

    def initialize(@config : Config, @content : BaseContent, @output_format : OutputFormat? = nil)
    end

    def site_title : String
      @config.title
    end

    def site_description : String
      @config.description
    end

    def site_author : String
      @config.author
    end

    def site_baseurl : String
      @config.baseurl
    end

    # Get CSS includes with proper theme cascade
    def css_includes(page_name : String? = nil) : String
      build_css_includes(page_name).join("\n  ")
    end

    # Legacy support for existing templates
    def site
      self
    end

    def title
      @content.title
    end

    def description
      @content.description || @content.excerpt
    end
  end

  class ArchiveContent < BaseContent
    property title : String
    property posts : Array(Content)
    property pagination_html : String

    def initialize(@title : String, @posts : Array(Content), @pagination_html : String = "")
    end

    def content : String
      posts_html = @posts.map do |post|
        date_str = post.date ? post.date.not_nil!.to_s(Lapis::DATE_FORMAT_HUMAN) : ""
        tags_html = post.tags.map { |tag| %(<span class="tag">#{tag}</span>) }.join(" ")

        <<-HTML
        <article class="post-item">
          <h3><a href="#{post.url}">#{post.title}</a></h3>
          <div class="meta">#{date_str} #{tags_html}</div>
          <p>#{post.excerpt}</p>
          <a href="#{post.url}" class="read-more">Read more →</a>
        </article>
        HTML
      end.join("\n")

      posts_html + @pagination_html
    end

    def url : String
      "/posts/"
    end

    def date : Time?
      @posts.first?.try(&.date)
    end

    def tags : Array(String)
      [] of String
    end

    def categories : Array(String)
      [] of String
    end

    def description : String?
      "Archive of all posts"
    end

    def excerpt(length : Int32 = 200) : String
      "Archive of all posts (#{@posts.size} posts)"
    end
  end

  class TemplateHelpers
    def self.format_date(date : Time?, format : String = "%B %d, %Y") : String
      date ? date.to_s(format) : ""
    end

    def self.excerpt(content : String, length : Int32 = 200) : String
      text = content.gsub(/<[^>]*>/, "")
      if text.size <= length
        text
      else
        text[0...length] + "..."
      end
    end

    def self.url_for(path : String, baseurl : String) : String
      if baseurl.ends_with?("/")
        baseurl.rchop + path
      else
        baseurl + path
      end
    end
  end
end