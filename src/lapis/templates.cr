require "ecr"
require "./base_content"

module Lapis
  class TemplateEngine
    property config : Config
    property layouts_dir : String
    property theme_layouts_dir : String

    def initialize(@config : Config)
      @layouts_dir = @config.layouts_dir
      @theme_layouts_dir = File.join(@config.theme_dir, "default", "layouts")
    end

    def render(content : Content, layout : String? = nil) : String
      layout_name = layout || content.layout
      context = TemplateContext.new(@config, content)
      
      render_with_inheritance(layout_name, context)
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

    private def find_layout(layout_name : String) : String?
      # Check local layouts first
      local_path = File.join(@layouts_dir, "#{layout_name}.html")
      return local_path if File.exists?(local_path)
      
      # Check theme layouts
      theme_path = File.join(@theme_layouts_dir, "#{layout_name}.html")
      return theme_path if File.exists?(theme_path)
      
      nil
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
      # Simple template processing - replace variables
      result = template

      # Replace basic variables
      result = result.gsub("{{ title }}", context.content.title)
      result = result.gsub("{{ content }}", context.content.content)
      result = result.gsub("{{ site.title }}", context.site_title)
      result = result.gsub("{{ site.description }}", context.site_description)
      result = result.gsub("{{ site.author }}", context.site_author)
      result = result.gsub("{{ site.baseurl }}", context.site_baseurl)

      # Date formatting
      if date = context.content.date
        result = result.gsub("{{ date }}", date.to_s(Lapis::DATE_FORMAT_SHORT))
        result = result.gsub("{{ date_formatted }}", date.to_s(Lapis::DATE_FORMAT_HUMAN))
      else
        result = result.gsub("{{ date }}", "")
        result = result.gsub("{{ date_formatted }}", "")
      end

      # Tags and categories
      tags_html = context.content.tags.map { |tag| %(<span class="tag">#{tag}</span>) }.join(" ")
      result = result.gsub("{{ tags }}", tags_html)

      categories_html = context.content.categories.map { |cat| %(<span class="category">#{cat}</span>) }.join(" ")
      result = result.gsub("{{ categories }}", categories_html)

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
    getter config : Config
    getter content : BaseContent

    def initialize(@config : Config, @content : BaseContent)
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