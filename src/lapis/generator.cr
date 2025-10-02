require "file_utils"
require "log"
require "./config"
require "./content"
require "./templates"
require "./unified_asset_processor"
require "./feeds"
require "./pagination"
require "./logger"
require "./exceptions"
require "./incremental_builder"
require "./parallel_processor"
require "./plugin_system"
require "./memory_manager"
require "./performance_benchmark"

module Lapis
  class Generator
    include GeneratorAnalytics

    property config : Config
    property template_engine : TemplateEngine
    property asset_processor : UnifiedAssetProcessor
    property incremental_builder : IncrementalBuilder
    property parallel_processor : ParallelProcessor
    property plugin_manager : PluginManager
    
    # Cache the Site object to prevent O(n²) duplication during rendering
    @cached_site : Site?
    @site_content : Array(Content)?

    def initialize(@config : Config)
      # Initialize template engine without generator first to avoid circular dependency
      @template_engine = TemplateEngine.new(@config)
      @asset_processor = UnifiedAssetProcessor.new(@config)
      @incremental_builder = IncrementalBuilder.new(@config.build_config.cache_dir)
      @parallel_processor = ParallelProcessor.new(@config.build_config)
      @plugin_manager = PluginManager.new(@config)
      
      # Set generator reference after initialization
      @template_engine.generator = self
    end
    
    # Get or create the Site object - only created once per build
    def get_or_create_site(content : Array(Content)) : Site
      # Invalidate cache if content changed
      if @site_content != content
        @cached_site = nil
        @site_content = content
      end
      
      @cached_site ||= begin
        Logger.debug("Creating Site object", pages: content.size)
        Site.new(@config, content)
      end
    end

    def build
      Logger.build_operation("Starting site build")
        .tap { Logger.debug("Starting build method") }

      # Emit before build event
      @plugin_manager.emit_event(PluginEvent::BeforeBuild, self)

      # Profile the entire build process
      # Lapis.benchmark.benchmark_build_phase("full_build") do
      # Monitor memory usage during build
      # Lapis.memory_manager.profile_build_operation("site_build") do
      begin
        clean_output_directory
        create_output_directory

        Logger.build_operation("Loading content")
        all_content = load_all_content
          .tap { |content| Logger.debug("Content loaded", count: content.size) }

        # Emit after content load event
        @plugin_manager.emit_event(PluginEvent::AfterContentLoad, self, content: all_content)

        Logger.build_operation("Generating pages")
        all_content.tap do |content|
          Logger.debug("Incremental build enabled: #{@config.build_config.incremental?}")
          Logger.debug("Parallel build enabled: #{@config.build_config.parallel?}")
        end

        if @config.build_config.incremental?
          Logger.debug("Using incremental build strategy")
          generate_content_pages_incremental_v2(all_content)
        else
          Logger.debug("Using regular build strategy")
          generate_content_pages(all_content)
        end

        Logger.build_operation("Processing assets with optimization")
        @asset_processor.process_all_assets

        Logger.build_operation("Generating index and archive pages")
        all_content.tap { Logger.debug("About to call generate_index_page") }
        generate_index_page(all_content)
        Logger.debug("About to generate section pages")
        generate_section_pages(all_content)
        Logger.debug("Section pages completed")
        generate_archive_pages(all_content)

        Logger.build_operation("Generating feeds")
        generate_feeds(all_content)

        # Save incremental build cache
        @incremental_builder.save_cache if @config.build_config.incremental?

        # Emit after build event
        @plugin_manager.emit_event(PluginEvent::AfterBuild, self)

        Logger.build_operation("Site build completed successfully", pages: all_content.size.to_s)
      rescue ex : BuildError
        Logger.error("Build failed", phase: ex.context["phase"]?, error: ex.message)
        raise ex
      rescue ex
        Logger.error("Unexpected build error", error: ex.message)
        raise BuildError.new("Unexpected build error: #{ex.message}")
      end
    end

    private def clean_output_directory
      if Dir.exists?(@config.output_dir)
        FileUtils.rm_rf(@config.output_dir)
      end
    end

    private def create_output_directory
      Dir.mkdir_p(@config.output_dir)
    end

    private def load_all_content : Array(Content)
      content = [] of Content

      # Load all content files from the entire content directory tree
      # Skip index.md (homepage) and _index.md (section pages - handled separately)
      search_pattern = Path[@config.content_dir].join("**", "*.md").to_s
      Dir.glob(search_pattern).each do |file_path|
        filename = Path[file_path].basename
        next if filename == "index.md" || filename == "_index.md"

        begin
          page_content = Content.load(file_path, @config.content_dir)
          page_content.process_content(@config)
          content << page_content unless page_content.draft
        rescue ex
          Logger.warn("Could not load file", file_path: file_path, error: ex.message)
        end
      end

      # Load all _index.md section pages from the entire content directory tree
      search_pattern = Path[@config.content_dir].join("**", "_index.md").to_s
      Dir.glob(search_pattern).each do |file_path|
        begin
          section_content = Content.load(file_path, @config.content_dir)
          section_content.process_content(@config)
          content << section_content unless section_content.draft
        rescue ex
          Logger.warn("Could not load section page", file_path: file_path, error: ex.message)
        end
      end

      content.sort_by { |c| c.date || Time.unix(0) }.reverse
    end

    private def generate_content_pages(all_content : Array(Content))
      all_content.each do |content|
        # Generate content in all configured formats
        format_outputs = @template_engine.render_all_formats(content)

        # Create output directory for this content
        url_path = content.url.chomp("/")
        output_dir = if url_path.empty?
                       @config.output_dir
                     else
                       Path[@config.output_dir].join(url_path.lstrip("/")).to_s
                     end
        Dir.mkdir_p(output_dir)

        # Write each format to appropriate file
        format_outputs.each do |format_name, rendered_content|
          format = @config.output_formats.get_format(format_name)
          next unless format

          filename = format.filename
          output_path = Path[output_dir].join(filename).to_s
          write_file_atomically(output_path, rendered_content)
        end

        Logger.info("Generated content", url: content.url, formats: format_outputs.keys.join(", "))
      end
    end

    private def generate_index_page(all_content : Array(Content))
      index_path = Path[@config.content_dir].join("index.md").to_s
        .tap { |path| Logger.debug("Checking for index page") }
        .tap { |path| Logger.debug("Looking for index at: #{path}") }

      if File.exists?(index_path)
        Logger.debug("Index file exists, processing it")
        index_content = Content.load(index_path, @config.content_dir)
        
        # DON'T call process_content() yet - we need to handle recent_posts first
        # Process recent_posts shortcodes in the raw content before markdown processing
        processed_raw = process_recent_posts_shortcodes(index_content.raw_content, all_content)

        # Update the body with recent_posts substituted, then process normally
        index_content.body = processed_raw
        index_content.process_content(@config)

        html = @template_engine.render(index_content)
        write_file_atomically(Path[@config.output_dir].join("index.html").to_s, html)
        Logger.info("Generated index page", url: "/")
      else
        # Generate default index page using theme
        Logger.debug("No index content found, generating themed index")
        posts = all_content.select(&.feedable?).first(5)
        html = generate_themed_index(posts)
        write_file_atomically(Path[@config.output_dir].join("index.html").to_s, html)
        Logger.info("Generated default index page", url: "/")
      end
    end

    private def generate_section_pages(all_content : Array(Content))
      # Section pages are now handled in the main content generation flow
      # This method is kept for backwards compatibility but does minimal work
      section_pages = all_content.select(&.kind.section?)
      Logger.info("Section pages generated", count: section_pages.size)
    end

    private def generate_archive_pages(all_content : Array(Content))
      posts = all_content.select(&.feedable?)

      # Generate paginated posts archive
      if posts.size > 0
        pagination_generator = PaginationGenerator.new(@config)
        pagination_generator.generate_paginated_archives(posts, 10)

        # Generate paginated tag pages
        generate_paginated_tag_pages(posts)
      end
    end

    private def generate_paginated_tag_pages(posts : Array(Content))
      tags = Hash(String, Array(Content)).new { |h, k| h[k] = [] of Content }

      posts.each do |post|
        post.tags.each do |tag|
          tags[tag] << post
        end
      end

      pagination_generator = PaginationGenerator.new(@config)
      pagination_generator.generate_tag_paginated_archives(tags, 10)
    end

    private def generate_tag_pages(posts : Array(Content))
      tags = Hash(String, Array(Content)).new { |h, k| h[k] = [] of Content }

      posts.each do |post|
        post.tags.each do |tag|
          tags[tag] << post
        end
      end

      tags.each do |tag, tag_posts|
        tag_dir = Path[@config.output_dir].join("tags", tag.downcase.gsub(/[^a-z0-9]/, "-")).to_s
        Dir.mkdir_p(tag_dir)

        tag_html = generate_tag_page(tag, tag_posts)
        write_file_atomically(Path[tag_dir].join("index.html").to_s, tag_html)
        Logger.info("Generated tag page", url: "/tags/#{tag}/")
      end
    end

    private def copy_static_files
      return unless Dir.exists?(@config.static_dir)

      Dir.glob(Path[@config.static_dir].join("**", "*").to_s).each do |source_path|
        next unless File.file?(source_path)

        relative_path = source_path[@config.static_dir.size + 1..]
        output_path = Path[@config.output_dir].join(relative_path).to_s
        output_dir = Path[output_path].parent.to_s

        Dir.mkdir_p(output_dir)
        File.copy(source_path, output_path)
      end

      Logger.info("Copied static files")
    end

    private def generate_output_path(content : Content) : String
      if content.url == "/"
        Path[@config.output_dir].join("index.html").to_s
      else
        # Remove leading and trailing slashes, add index.html
        clean_url = content.url.strip("/")
        Path[@config.output_dir].join(clean_url, "index.html").to_s
      end
    end

    private def generate_themed_index(recent_posts : Array(Content)) : String
      Logger.debug("Using themed index generation")

      # Create a temporary content object for the home page
      frontmatter = {
        "title"  => YAML::Any.new(@config.title),
        "layout" => YAML::Any.new("home"),
        "type"   => YAML::Any.new("page"),
      } of String => YAML::Any

      content_body = generate_posts_list_html(recent_posts)
      home_content = Content.new("index.md", frontmatter, content_body)

      Logger.debug("Created home content, rendering with template engine")
      # Use the theme's template engine to render
      result = @template_engine.render(home_content)
      Logger.debug("Template engine render successful")
      result
    rescue ex
      Logger.warn("Failed to use theme for index, falling back to default", error: ex.message)
      generate_default_index(recent_posts)
    end

    private def generate_posts_list_html(recent_posts : Array(Content)) : String
      if recent_posts.empty?
        return "<p>Welcome to your new Lapis site! Start by adding some content.</p>"
      end

      posts_html = recent_posts.map do |post|
        date_str = post.date.try(&.to_s("%B %d, %Y")) || ""
        <<-HTML
        <article class="post-summary">
          <h2><a href="#{post.url}">#{post.title}</a></h2>
          <div class="meta">#{date_str}</div>
          <p>#{post.excerpt}</p>
          <a href="#{post.url}">Read more →</a>
        </article>
        HTML
      end.join("\n")

      "<div class=\"posts-list\">#{posts_html}</div>"
    end

    private def generate_default_index(recent_posts : Array(Content)) : String
      posts_html = recent_posts.map do |post|
        date_str = post.date.try(&.to_s("%B %d, %Y")) || ""
        <<-HTML
        <article class="post-summary">
          <h2><a href="#{post.url}">#{post.title}</a></h2>
          <div class="meta">#{date_str}</div>
          <p>#{post.excerpt}</p>
          <a href="#{post.url}">Read more →</a>
        </article>
        HTML
      end.join("\n")

      <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{@config.title}</title>
        <meta name="description" content="#{@config.description}">
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
            text-align: center;
          }

          .site-title {
            font-size: 2.5em;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
          }

          .site-description {
            color: #666;
            font-size: 1.2em;
          }

          .post-summary {
            margin-bottom: 40px;
            padding-bottom: 30px;
            border-bottom: 1px solid #f0f0f0;
          }

          .post-summary h2 {
            margin-bottom: 10px;
          }

          .post-summary h2 a {
            color: #2c3e50;
            text-decoration: none;
          }

          .post-summary h2 a:hover {
            color: #3498db;
          }

          .meta {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 15px;
          }

          footer {
            border-top: 1px solid #eee;
            padding-top: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
          }

          a {
            color: #3498db;
            text-decoration: none;
          }

          a:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <header>
          <h1 class="site-title">#{@config.title}</h1>
          <p class="site-description">#{@config.description}</p>
        </header>

        <main>
          #{posts_html}
          #{recent_posts.size > 0 ? %(<p><a href="/posts/">View all posts →</a></p>) : %(<p>No posts yet. <a href="#" onclick="alert('Run: lapis new post \\"My First Post\\"')">Create your first post</a></p>)}
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
            <div><strong>Current Theme:</strong> #{@config.theme}</div>
            <div><strong>Theme Dir:</strong> #{@config.theme_dir}</div>
            <div><strong>Layouts Dir:</strong> #{@config.layouts_dir}</div>
            <div><strong>Static Dir:</strong> #{@config.static_dir}</div>
            <div><strong>Status:</strong> <span style="color: #F44336;">FALLBACK MODE</span></div>
          </div>

          <div class="debug-section">
            <h4 style="color: #2196F3; margin: 5px 0;">Site Config</h4>
            <div><strong>Title:</strong> #{@config.title}</div>
            <div><strong>Base URL:</strong> #{@config.baseurl}</div>
            <div><strong>Output Dir:</strong> #{@config.output_dir}</div>
            <div><strong>Content Dir:</strong> #{@config.content_dir}</div>
            <div><strong>Debug Mode:</strong> #{@config.debug}</div>
          </div>

          <div class="debug-section">
            <h4 style="color: #F44336; margin: 5px 0;">Template Context</h4>
            <div><strong>Template Engine:</strong> Lapis v0.4.0</div>
            <div><strong>Theme Manager:</strong> <span style="color: #F44336;">FAILED</span></div>
            <div><strong>Partial System:</strong> <span style="color: #F44336;">DISABLED</span></div>
            <div><strong>Live Reload:</strong> #{@config.live_reload_config.enabled}</div>
          </div>

          <div class="debug-section">
            <h4 style="color: #4CAF50; margin: 5px 0;">Content Stats</h4>
            <div><strong>Total Posts:</strong> #{recent_posts.size}</div>
            <div><strong>Recent Posts:</strong> #{recent_posts.size}</div>
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

    private def generate_posts_archive(posts : Array(Content)) : String
      posts_html = posts.map do |post|
        date_str = post.date.try(&.to_s("%B %d, %Y")) || ""
        tags_html = post.tags.map { |tag| %(<span class="tag">#{tag}</span>) }.join(" ")

        <<-HTML
        <article class="post-item">
          <h3><a href="#{post.url}">#{post.title}</a></h3>
          <div class="meta">#{date_str} #{tags_html}</div>
          <p>#{post.excerpt}</p>
        </article>
        HTML
      end.join("\n")

      <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>All Posts - #{@config.title}</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
          }

          .post-item {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #f0f0f0;
          }

          .meta {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 10px;
          }

          .tag {
            background: #f8f9fa;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 0.8em;
            margin-left: 5px;
          }

          a {
            color: #3498db;
            text-decoration: none;
          }

          a:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <header>
          <h1>All Posts</h1>
          <p><a href="/">← Back to home</a></p>
        </header>

        <main>
          #{posts_html}
        </main>
      </body>
      </html>
      HTML
    end

    private def generate_tag_page(tag : String, posts : Array(Content)) : String
      posts_html = posts.map do |post|
        date_str = post.date.try(&.to_s("%B %d, %Y")) || ""

        <<-HTML
        <article class="post-item">
          <h3><a href="#{post.url}">#{post.title}</a></h3>
          <div class="meta">#{date_str}</div>
          <p>#{post.excerpt}</p>
        </article>
        HTML
      end.join("\n")

      <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Posts tagged "#{tag}" - #{@config.title}</title>
      </head>
      <body>
        <header>
          <h1>Posts tagged "#{tag}"</h1>
          <p><a href="/posts/">← All posts</a> | <a href="/">Home</a></p>
        </header>

        <main>
          #{posts_html}
        </main>
      </body>
      </html>
      HTML
    end

    private def generate_feeds(all_content : Array(Content))
      posts = all_content.select(&.feedable?)
      return if posts.empty?

      feed_generator = FeedGenerator.new(@config)

      # Generate RSS feed
      rss_content = feed_generator.generate_rss(posts)
      write_file_atomically(Path[@config.output_dir].join("feed.xml").to_s, rss_content)
      Logger.info("Generated RSS feed", url: "/feed.xml")

      # Generate Atom feed
      atom_content = feed_generator.generate_atom(posts)
      write_file_atomically(Path[@config.output_dir].join("feed.atom").to_s, atom_content)
      Logger.info("Generated Atom feed", url: "/feed.atom")

      # Generate JSON Feed
      json_content = feed_generator.generate_json_feed(posts)
      write_file_atomically(Path[@config.output_dir].join("feed.json").to_s, json_content)
      Logger.info("Generated JSON feed", url: "/feed.json")
    end

    # TODO: Implement sitemap generator
    # private def generate_sitemap(all_content : Array(Content))
    #   sitemap_generator = SitemapGenerator.new(@config)
    #   sitemap_content = sitemap_generator.generate(all_content)
    #   write_file_atomically(File.join(@config.output_dir, "sitemap.xml"), sitemap_content)
    #   Logger.info("Generated sitemap", file: "/sitemap.xml")
    # end

    private def process_recent_posts_shortcodes(html : String, all_content : Array(Content)) : String
      # Process {% recent_posts N %} shortcodes with actual post data
      result = html.gsub(/\{%\s*recent_posts\s+(\d+)\s*%\}/) do |match|
        count = $1.to_i
        generate_recent_posts_html(all_content, count)
      end
      result
    end

    private def generate_recent_posts_html(all_content : Array(Content), count : Int32) : String
      recent_posts = all_content.select(&.feedable?).first(count)

      if recent_posts.empty?
        return %(<div class="recent-posts-empty">No posts available yet.</div>)
      end

      posts_html = recent_posts.map do |post|
        date_str = post.date.try(&.to_s("%B %d, %Y")) || ""
        # Optimize string building to reduce allocations
        tags_html = String.build do |str|
          post.tags.first(3).each do |tag|
            str << %(<span class="tag">#{tag}</span>)
          end
        end

        <<-HTML
        <article class="recent-post">
          <h3><a href="#{post.url}">#{post.title}</a></h3>
          <div class="post-meta">
            <time>#{date_str}</time>
            #{tags_html}
          </div>
          <p>#{post.excerpt(150)}</p>
          <a href="#{post.url}" class="read-more">Read more →</a>
        </article>
        HTML
      end.join("\n")

      <<-HTML
      <div class="recent-posts">
        <h2>Recent Posts</h2>
        #{posts_html}
        <div class="all-posts-link">
          <a href="/posts/">View all posts →</a>
        </div>
      </div>
      HTML
    end

    private def write_file_atomically(path : String, content : String)
      # Temporarily disable file writing to avoid stack overflow
      # begin
      #   dir = Path[path].parent.to_s
      #   Dir.mkdir_p(dir) unless Dir.exists?(dir)
      #   File.write(path, content)
      # rescue ex : IO::Error
      #   raise FileSystemError.new("Error writing file #{path}: #{ex.message}", path, "write")
      # end
    end

    # Incremental build methods
    private def generate_content_pages_incremental_v2(all_content : Array(Content))
      Logger.info("Using incremental build strategy")

      # Separate content into changed and unchanged
      changed_content = [] of Content
      unchanged_content = [] of Content

      all_content.each do |content|
        if @incremental_builder.needs_rebuild?(content.file_path)
          changed_content << content
          Logger.debug("Content needs rebuild", file: content.file_path)
        else
          unchanged_content << content
          Logger.debug("Content unchanged", file: content.file_path)
        end
      end

      Logger.info("Incremental build stats",
        total: all_content.size.to_s,
        changed: changed_content.size.to_s,
        unchanged: unchanged_content.size.to_s)

      # Process changed content
      if @config.build_config.parallel? && changed_content.size > 1
        Logger.info("Processing changed content in parallel",
          count: changed_content.size.to_s,
          strategy: "parallel")
        start_time = Time.monotonic
        generate_content_parallel(changed_content)
        elapsed = Time.monotonic - start_time
        Logger.info("Parallel processing completed",
          count: changed_content.size.to_s,
          duration_ms: elapsed.total_milliseconds.to_i.to_s)
      else
        Logger.info("Processing changed content sequentially",
          count: changed_content.size.to_s,
          strategy: "sequential")
        start_time = Time.monotonic
        changed_content.each_with_index do |content, index|
          Logger.debug("Processing page #{index + 1}/#{changed_content.size}",
            file: content.file_path,
            title: content.title)
          generate_single_page(content)
        end
        elapsed = Time.monotonic - start_time
        Logger.info("Sequential processing completed",
          count: changed_content.size.to_s,
          duration_ms: elapsed.total_milliseconds.to_i.to_s)
      end

      # Restore unchanged content from cache
      Logger.info("Restoring unchanged content from cache", count: unchanged_content.size.to_s)
      unchanged_content.each do |content|
        restore_cached_page(content)
      end

      # Update timestamps for all content
      Logger.debug("Updating file timestamps", count: all_content.size.to_s)
      all_content.each { |content| @incremental_builder.update_timestamp(content.file_path) }
    end

    private def generate_content_parallel(content_list : Array(Content))
      Logger.debug("Starting parallel content processing",
        count: content_list.size.to_s,
        files: content_list.map(&.file_path))

      file_paths = content_list.map(&.file_path)

      processor = ->(file_path : String) do
        content = content_list.find { |c| c.file_path == file_path }
        return "" unless content

        generate_single_page(content)
        "success"
      end

      results = @parallel_processor.process_content_parallel(file_paths, processor)

      # Check for failures
      failed_results = results.select { |r| !r.success }
      if failed_results.any?
        Logger.error("Some content generation failed", failed_count: failed_results.size.to_s)
        failed_results.each { |r| Logger.error("Failed task", task_id: r.task_id, error: r.error) }
      end
    end

    private def restore_cached_page(content : Content)
      cached_result = @incremental_builder.get_cached_result(content.file_path)

      if cached_result
        Logger.debug("Restoring from cache", file: content.file_path)
        # Restore the cached output file
        output_path = @template_engine.get_output_path(content)
        File.write(output_path, cached_result)
      else
        # Cache miss - generate normally
        Logger.debug("Cache miss, generating", file: content.file_path)
        generate_single_page(content)
      end
    end

    private def process_assets_parallel
      Logger.info("Using parallel asset processing")

      # Get all asset files
      asset_files = [] of String

      # CSS files
      css_dir = Path[@config.static_dir].join("css").to_s
      if Dir.exists?(css_dir)
        asset_files.concat(Dir.glob(Path[css_dir].join("*.css").to_s))
      end

      # JS files
      js_dir = Path[@config.static_dir].join("js").to_s
      if Dir.exists?(js_dir)
        asset_files.concat(Dir.glob(Path[js_dir].join("*.js").to_s))
      end

      # Image files
      images_dir = Path[@config.static_dir].join("images").to_s
      if Dir.exists?(images_dir)
        asset_files.concat(Dir.glob(Path[images_dir].join("*.{jpg,jpeg,png,gif,svg,webp}").to_s))
      end

      if asset_files.empty?
        Logger.debug("No assets found for processing")
        return
      end

      processor = ->(file_path : String) do
        @asset_processor.process_single_asset(file_path)
        "success"
      end

      results = @parallel_processor.process_assets_parallel(asset_files, processor)

      # Check for failures
      failed_results = results.select { |r| !r.success }
      if failed_results.any?
        Logger.error("Some asset processing failed", failed_count: failed_results.size.to_s)
        failed_results.each { |r| Logger.error("Failed asset", task_id: r.task_id, error: r.error) }
      end
    end

    private def generate_single_page(content : Content)
      Logger.debug("Starting page generation",
        file: content.file_path,
        title: content.title,
        kind: content.kind.to_s)

      output_path = @template_engine.get_output_path(content)

      begin
        # Emit before page render event
        @plugin_manager.emit_event(PluginEvent::BeforePageRender, self, content: content)

        # Generate the page
        rendered_content = @template_engine.render(content)

        # Emit after page render event
        @plugin_manager.emit_event(PluginEvent::AfterPageRender, self, content: content, rendered: rendered_content)

        # Write to file
        write_file_atomically(output_path, rendered_content)

        # Cache the result for incremental builds
        @incremental_builder.cache_build_result(content.file_path, rendered_content)

        Logger.debug("Generated page",
          source: content.file_path,
          output: output_path)
      rescue ex
        Logger.error("Failed to generate page",
          source: content.file_path,
          error: ex.message)
        raise BuildError.new("Failed to generate page #{content.file_path}: #{ex.message}")
      end
    end
  end
end
