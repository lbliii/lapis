require "ecr"
require "./base_content"
require "./theme_helpers"
require "./partials"
require "./page_operations"
require "./navigation"
require "./collections"
require "./content_query"
require "./cross_references"
require "./template_processor"
require "./function_processor"
require "./theme_manager"
require "./theme"

module Lapis
  class TemplateEngine
    include ThemeHelpers

    property config : Config
    property layouts_dir : String
    property theme_layouts_dir : String
    property theme_manager : ThemeManager

    def initialize(@config : Config)
      @layouts_dir = @config.layouts_dir
      @theme_layouts_dir = File.join(@config.theme_dir, "layouts")
      @theme_manager = ThemeManager.new(@config.theme, @config.root_dir, @config.theme_dir)

      # Validate theme is available
      unless @theme_manager.theme_available?
        Logger.warn("Configured theme not available, falling back to default",
          theme: @config.theme)
        @theme_manager = ThemeManager.new("default", @config.root_dir)
      end
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

    def get_output_path(content : Content, output_format : OutputFormat? = nil) : String
      # Determine the output format
      format = output_format || @config.output_formats.formats_for_kind(content.kind).first?

      # Generate the URL path
      url_path = content.url

      # Determine the file extension
      extension = format ? format.extension : "html"

      # Build the output path
      if url_path.ends_with?("/")
        # Directory-style URL
        File.join(@config.output_dir, url_path, "index.#{extension}")
      else
        # File-style URL
        File.join(@config.output_dir, "#{url_path}.#{extension}")
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

      # Use ThemeManager for layout resolution
      @theme_manager.resolve_file("#{layout_name}.html", "layout")
    end

    # Template lookup order based on page kind and output format
    private def find_layout_by_page_kind_and_format(content : Content, output_format : OutputFormat?) : String?
      format_suffix = output_format ? ".#{output_format.name}" : ""
      extension = output_format ? output_format.extension : "html"

      # Build candidates in priority order and use ThemeManager to resolve
      case content.kind
      when .single?
        # For single pages: section/single -> _default/single -> explicit layout
        candidates = [] of String
        unless content.section.empty?
          candidates << File.join(content.section, "single#{format_suffix}.#{extension}")
          candidates << File.join(content.section, "single.#{extension}")
        end
        candidates << File.join("_default", "single#{format_suffix}.#{extension}")
        candidates << File.join("_default", "single.#{extension}")

        # Fallback to explicit layout if specified
        if content.layout != "default"
          candidates << "#{content.layout}#{format_suffix}.#{extension}"
          candidates << "#{content.layout}.#{extension}"
        end
      when .list?, .section?
        # For list/section pages: section/list -> _default/list
        candidates = [] of String
        unless content.section.empty?
          candidates << File.join(content.section, "list#{format_suffix}.#{extension}")
          candidates << File.join(content.section, "list.#{extension}")
        end
        candidates << File.join("_default", "list#{format_suffix}.#{extension}")
        candidates << File.join("_default", "list.#{extension}")
      when .home?
        # For home page: index -> _default/home -> _default/list
        candidates = [] of String
        candidates << "index#{format_suffix}.#{extension}"
        candidates << "index.#{extension}"
        candidates << File.join("_default", "home#{format_suffix}.#{extension}")
        candidates << File.join("_default", "home.#{extension}")
        candidates << File.join("_default", "list#{format_suffix}.#{extension}")
        candidates << File.join("_default", "list.#{extension}")
      when .taxonomy?
        # For taxonomy pages: taxonomy -> _default/taxonomy -> _default/list
        candidates = [] of String
        candidates << "taxonomy#{format_suffix}.#{extension}"
        candidates << "taxonomy.#{extension}"
        candidates << File.join("_default", "taxonomy#{format_suffix}.#{extension}")
        candidates << File.join("_default", "taxonomy.#{extension}")
        candidates << File.join("_default", "list#{format_suffix}.#{extension}")
        candidates << File.join("_default", "list.#{extension}")
      when .term?
        # For term pages: term -> _default/term -> _default/list
        candidates = [] of String
        candidates << "term#{format_suffix}.#{extension}"
        candidates << "term.#{extension}"
        candidates << File.join("_default", "term#{format_suffix}.#{extension}")
        candidates << File.join("_default", "term.#{extension}")
        candidates << File.join("_default", "list#{format_suffix}.#{extension}")
        candidates << File.join("_default", "list.#{extension}")
      else
        candidates = [] of String
      end

      # Use ThemeManager to resolve first existing template
      candidates.each do |candidate|
        if resolved_path = @theme_manager.resolve_file(candidate, "layout")
          return resolved_path
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
      # Process partials first
      result = Partials.process_partials(template, context, @theme_manager)

      # Use the advanced function processor
      function_processor = FunctionProcessor.new(context)
      result = function_processor.process(result)

      # Legacy CSS includes support (will be deprecated)
      result = result.gsub("{{ css_includes }}", context.css_includes)

      # Auto CSS discovery (preferred method) - ensure CSS is included
      result = result.gsub("{{ auto_css }}", Partials.generate_auto_css(context))

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

        <!-- Theme Debug Information -->
        <div id="lapis-debug" style="position: fixed; bottom: 0; right: 0; width: 400px; max-height: 300px; background: #1a1a1a; color: #fff; font-family: monospace; font-size: 12px; padding: 10px; border: 1px solid #333; z-index: 9999; overflow-y: auto; display: none;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
            <h3 style="margin: 0; color: #4CAF50;">🔧 Lapis Debug</h3>
            <button onclick="toggleDebug()" style="background: #333; color: #fff; border: 1px solid #555; padding: 2px 6px; cursor: pointer;">×</button>
          </div>
          
          <div class="debug-section">
            <h4 style="color: #FF9800; margin: 5px 0;">Theme Info</h4>
            <div><strong>Current Theme:</strong> {{ site.theme }}</div>
            <div><strong>Theme Dir:</strong> {{ site.theme_dir }}</div>
            <div><strong>Layouts Dir:</strong> {{ site.layouts_dir }}</div>
            <div><strong>Static Dir:</strong> {{ site.static_dir }}</div>
            <div><strong>Status:</strong> <span style="color: #F44336;">FALLBACK MODE</span></div>
          </div>

          <div class="debug-section">
            <h4 style="color: #2196F3; margin: 5px 0;">Page Info</h4>
            <div><strong>Layout:</strong> {{ page.layout | default: "default" }}</div>
            <div><strong>Kind:</strong> {{ page.kind | default: "page" }}</div>
            <div><strong>URL:</strong> {{ page.url | default: "/" }}</div>
            <div><strong>File Path:</strong> {{ page.file_path | default: "N/A" }}</div>
            <div><strong>Output Path:</strong> {{ page.output_path | default: "N/A" }}</div>
          </div>

          <div class="debug-section">
            <h4 style="color: #9C27B0; margin: 5px 0;">Site Config</h4>
            <div><strong>Title:</strong> {{ site.title }}</div>
            <div><strong>Base URL:</strong> {{ site.baseurl }}</div>
            <div><strong>Output Dir:</strong> {{ site.output_dir }}</div>
            <div><strong>Content Dir:</strong> {{ site.content_dir }}</div>
            <div><strong>Debug Mode:</strong> {{ site.debug | default: false }}</div>
          </div>

          <div class="debug-section">
            <h4 style="color: #F44336; margin: 5px 0;">Template Context</h4>
            <div><strong>Template Engine:</strong> Lapis v0.4.0</div>
            <div><strong>Theme Manager:</strong> <span style="color: #F44336;">FAILED</span></div>
            <div><strong>Partial System:</strong> <span style="color: #F44336;">DISABLED</span></div>
            <div><strong>Live Reload:</strong> {{ site.live_reload_config.enabled | default: true }}</div>
          </div>

          <div class="debug-section">
            <h4 style="color: #4CAF50; margin: 5px 0;">Content Stats</h4>
            <div><strong>Total Posts:</strong> {{ posts.all.size }}</div>
            <div><strong>Total Pages:</strong> {{ pages.all.size }}</div>
            <div><strong>Tags:</strong> {{ tags.size }}</div>
            <div><strong>Categories:</strong> {{ categories.size }}</div>
          </div>

          <div class="debug-section">
            <h4 style="color: #795548; margin: 5px 0;">Template Resolution</h4>
            <div><strong>Current Template:</strong> <span style="color: #F44336;">FALLBACK</span></div>
            <div><strong>Template Engine:</strong> Lapis Fallback</div>
            <div><strong>Partial System:</strong> <span style="color: #F44336;">NOT AVAILABLE</span></div>
            <div><strong>Theme Helpers:</strong> <span style="color: #F44336;">DISABLED</span></div>
          </div>

          <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid #333; font-size: 10px; color: #888;">
            <div>Press <kbd style="background: #333; padding: 2px 4px; border-radius: 2px;">Ctrl+D</kbd> to toggle</div>
            <div>Add <kbd style="background: #333; padding: 2px 4px; border-radius: 2px;">?debug=true</kbd> to URL</div>
            <div>Set <kbd style="background: #333; padding: 2px 4px; border-radius: 2px;">debug: true</kbd> in config</div>
          </div>
        </div>

        <script>
        let debugVisible = false;

        function toggleDebug() {
          const debugPanel = document.getElementById('lapis-debug');
          if (debugPanel) {
            debugVisible = !debugVisible;
            debugPanel.style.display = debugVisible ? 'block' : 'none';
          }
        }

        // Keyboard shortcut to toggle debug panel
        document.addEventListener('keydown', function(e) {
          if (e.ctrlKey && e.key === 'd') {
            e.preventDefault();
            toggleDebug();
          }
        });

        // Auto-show debug panel in development mode or with ?debug=true
        function shouldShowDebug() {
          const urlParams = new URLSearchParams(window.location.search);
          return window.location.hostname === 'localhost' || 
                 window.location.hostname === '127.0.0.1' ||
                 urlParams.get('debug') === 'true' ||
                 urlParams.get('lapis-debug') === 'true';
        }

        if (shouldShowDebug()) {
          setTimeout(() => {
            const debugPanel = document.getElementById('lapis-debug');
            if (debugPanel) {
              debugPanel.style.display = 'block';
              debugVisible = true;
            }
          }, 1000);
        }
        </script>

        <style>
        #lapis-debug {
          box-shadow: -2px -2px 10px rgba(0,0,0,0.3);
          border-radius: 5px 0 0 0;
        }

        #lapis-debug .debug-section {
          margin-bottom: 8px;
          padding-bottom: 5px;
          border-bottom: 1px solid #333;
        }

        #lapis-debug .debug-section:last-child {
          border-bottom: none;
        }

        #lapis-debug div {
          margin: 2px 0;
          word-break: break-all;
        }

        #lapis-debug strong {
          color: #fff;
          font-weight: bold;
        }

        kbd {
          font-family: monospace;
          font-size: 10px;
        }
        </style>
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
    getter page_ops : PageOperations?
    getter nav_builder : NavigationBuilder
    getter collections : ContentCollections
    getter query : ContentQuery
    getter cross_refs : CrossReferenceEngine

    @site_content : Array(Content)

    def initialize(@config : Config, @content : BaseContent, @output_format : OutputFormat? = nil)
      # Load all site content for advanced operations
      @site_content = load_site_content

      # Initialize v0.4.0 features
      site_config = {} of String => YAML::Any # Empty config for now - could be loaded from config file
      @nav_builder = NavigationBuilder.new(@site_content, site_config)
      @collections = ContentCollections.new(@site_content, site_config)
      @query = ContentQuery.new(@site_content, @collections)
      @cross_refs = CrossReferenceEngine.new(@site_content)

      # Initialize page operations if content is a Content object
      if @content.is_a?(Content)
        @page_ops = PageOperations.new(@content.as(Content), @site_content)
      end
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

    # Page operations (advanced methods)
    def page
      @page_ops
    end

    def summary
      @page_ops.try(&.summary) || @content.excerpt
    end

    def reading_time
      @page_ops.try(&.reading_time) || 1
    end

    def word_count
      @page_ops.try(&.word_count) || 0
    end

    def tags
      @page_ops.try(&.tags) || [] of String
    end

    def categories
      @page_ops.try(&.categories) || [] of String
    end

    def related_content(limit : Int32 = 5)
      @page_ops.try(&.related(limit)) || [] of Content
    end

    # Navigation methods
    def breadcrumbs
      if @content.is_a?(Content)
        @nav_builder.breadcrumbs(@content.as(Content))
      else
        [] of BreadcrumbItem
      end
    end

    def site_menu(name : String = "main")
      @nav_builder.site_menu(name)
    end

    def section_nav
      if @content.is_a?(Content)
        @nav_builder.section_navigation(@content.as(Content))
      else
        SectionNavigation.new
      end
    end

    # Content collections and queries
    def posts
      @query.posts
    end

    def pages
      @query.pages
    end

    def recent_posts(count : Int32 = 5)
      @query.recent(count)
    end

    def content_where(**filters)
      @query.where(**filters)
    end

    def content_by_tag(tag : String)
      @query.by_tag(tag)
    end

    def content_by_section(section : String)
      @query.by_section(section)
    end

    # Cross-references
    def backlinks
      if @content.is_a?(Content)
        @cross_refs.find_backlinks(@content.as(Content))
      else
        [] of Content
      end
    end

    # Template helpers for common patterns
    def tag_cloud
      @collections.tag_cloud("posts")
    end

    def archive_by_year
      posts.all.group_by { |post| post.date.try(&.year) || 0 }
    end

    def archive_by_month
      posts.all.group_by { |post|
        date = post.date
        date ? "#{date.year}-#{date.month.to_s.rjust(2, '0')}" : "undated"
      }
    end

    private def load_site_content : Array(Content)
      content = [] of Content

      # This is a simplified version - in a real implementation,
      # this would use the generator's content loading logic
      if Dir.exists?(@config.content_dir)
        Dir.glob(File.join(@config.content_dir, "**", "*.md")).each do |file_path|
          next if File.basename(file_path) == "index.md"
          begin
            page_content = Content.load(file_path, @config.content_dir)
            page_content.process_content(@config)
            content << page_content unless page_content.draft
          rescue ex
            # Skip files that can't be loaded
          end
        end
      end

      content.sort_by { |c| c.date || Time.unix(0) }.reverse
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

    def self.read_template_file(file_path : String) : String
      File.open(file_path, "r") do |file|
        file.set_encoding("UTF-8")
        file.gets_to_end
      end
    rescue ex : File::NotFoundError
      raise "Template file not found: #{file_path}"
    rescue ex : IO::Error
      raise "Error reading template file #{file_path}: #{ex.message}"
    end
  end
end
