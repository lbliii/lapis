require "ecr"

module Lapis
  class TemplateEngine
    property config : Config
    property layouts_dir : String

    def initialize(@config : Config)
      @layouts_dir = @config.layouts_dir
    end

    def render(content : Content, layout : String? = nil) : String
      layout_name = layout || content.layout
      layout_path = File.join(@layouts_dir, "#{layout_name}.html")

      if File.exists?(layout_path)
        render_layout(layout_path, content)
      else
        render_default_layout(content)
      end
    end

    def render_layout(layout_path : String, content : Content) : String
      layout_content = File.read(layout_path)
      context = TemplateContext.new(@config, content)
      process_template(layout_content, context)
    end

    def render_default_layout(content : Content) : String
      context = TemplateContext.new(@config, content)
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
        result = result.gsub("{{ date }}", date.to_s("%Y-%m-%d"))
        result = result.gsub("{{ date_formatted }}", date.to_s("%B %d, %Y"))
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
    getter content : Content

    def initialize(@config : Config, @content : Content)
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