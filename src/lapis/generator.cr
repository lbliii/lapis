require "file_utils"
require "log"
require "./config"
require "./content"
require "./templates"
require "./assets"
require "./feeds"
require "./pagination"
require "./logger"
require "./exceptions"
require "./incremental_builder"
require "./parallel_processor"
require "./plugin_system"
require "./asset_pipeline"
require "./memory_manager"
require "./performance_benchmark"

module Lapis
  class Generator
    include GeneratorAnalytics

    property config : Config
    property template_engine : TemplateEngine
    property asset_processor : AssetProcessor
    property asset_pipeline : AssetPipeline
    property incremental_builder : IncrementalBuilder
    property parallel_processor : ParallelProcessor
    property plugin_manager : PluginManager

    def initialize(@config : Config)
      @template_engine = TemplateEngine.new(@config)
      @asset_processor = AssetProcessor.new(@config)
      @asset_pipeline = AssetPipeline.new(@config)
      @incremental_builder = IncrementalBuilder.new(@config.build_config.cache_dir)
      @parallel_processor = ParallelProcessor.new(@config.build_config)
      @plugin_manager = PluginManager.new(@config)
    end

    def build
      puts "DEBUG: Starting build method"
      Logger.build_operation("Starting site build")

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

        # Emit after content load event
        @plugin_manager.emit_event(PluginEvent::AfterContentLoad, self, content: all_content)

        Logger.build_operation("Generating pages")
        puts "DEBUG: Incremental build enabled: #{@config.build_config.incremental}"
        puts "DEBUG: Parallel build enabled: #{@config.build_config.parallel}"
        if @config.build_config.incremental
          puts "DEBUG: Using incremental build strategy"
          generate_content_pages_incremental_v2(all_content)
        else
          puts "DEBUG: Using regular build strategy"
          generate_content_pages(all_content)
        end

        Logger.build_operation("Processing assets with optimization")
        if @config.build_config.parallel
          # Use advanced asset pipeline
          @asset_pipeline.process_all_assets
        else
          # Use legacy asset processor
          @asset_processor.process_all_assets
        end

        Logger.build_operation("Generating index and archive pages")
        generate_index_page(all_content)
        Logger.debug("About to generate section pages")
        generate_section_pages(all_content)
        Logger.debug("Section pages completed")
        generate_archive_pages(all_content)

        Logger.build_operation("Generating feeds")
        generate_feeds(all_content)

        # Save incremental build cache
        @incremental_builder.save_cache if @config.build_config.incremental

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
      search_pattern = File.join(@config.content_dir, "**", "*.md")
      Dir.glob(search_pattern).each do |file_path|
        filename = File.basename(file_path)
        next if filename == "index.md" || filename == "_index.md"

        begin
          page_content = Content.load(file_path, @config.content_dir)
          page_content.process_content(@config)
          content << page_content unless page_content.draft
        rescue ex
          puts "Warning: Could not load #{file_path}: #{ex.message}"
        end
      end

      # Load all _index.md section pages from the entire content directory tree
      search_pattern = File.join(@config.content_dir, "**", "_index.md")
      Dir.glob(search_pattern).each do |file_path|
        begin
          section_content = Content.load(file_path, @config.content_dir)
          section_content.process_content(@config)
          content << section_content unless section_content.draft
        rescue ex
          puts "Warning: Could not load section page #{file_path}: #{ex.message}"
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
                       File.join(@config.output_dir, url_path.lstrip("/"))
                     end
        Dir.mkdir_p(output_dir)

        # Write each format to appropriate file
        format_outputs.each do |format_name, rendered_content|
          format = @config.output_formats.get_format(format_name)
          next unless format

          filename = format.filename
          output_path = File.join(output_dir, filename)
          write_file_atomically(output_path, rendered_content)
        end

        puts "  Generated: #{content.url} (#{format_outputs.keys.join(", ")})"
      end
    end

    private def generate_index_page(all_content : Array(Content))
      index_path = File.join(@config.content_dir, "index.md")

      if File.exists?(index_path)
        index_content = Content.load(index_path, @config.content_dir)
        index_content.process_content(@config)

        # Process recent_posts shortcodes in the raw content before markdown processing
        processed_raw = process_recent_posts_shortcodes(index_content.raw_content, all_content)

        # Re-process the markdown with the substituted content
        processor = ShortcodeProcessor.new(@config)
        processed_markdown = processor.process(processed_raw)

        options = Markd::Options.new(smart: true, safe: false)
        index_content.content = Markd.to_html(processed_markdown, options)

        html = @template_engine.render(index_content)
        write_file_atomically(File.join(@config.output_dir, "index.html"), html)
        puts "  Generated: /"
      else
        # Generate default index page
        posts = all_content.select(&.is_post_layout?).first(5)
        html = generate_default_index(posts)
        write_file_atomically(File.join(@config.output_dir, "index.html"), html)
        puts "  Generated: / (default)"
      end
    end

    private def generate_section_pages(all_content : Array(Content))
      # Section pages are now handled in the main content generation flow
      # This method is kept for backwards compatibility but does minimal work
      section_pages = all_content.select(&.kind.section?)
      puts "  Section pages already generated in main flow: #{section_pages.size} pages"
    end

    private def generate_archive_pages(all_content : Array(Content))
      posts = all_content.select(&.is_post_layout?)

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
        tag_dir = File.join(@config.output_dir, "tags", tag.downcase.gsub(/[^a-z0-9]/, "-"))
        Dir.mkdir_p(tag_dir)

        tag_html = generate_tag_page(tag, tag_posts)
        write_file_atomically(File.join(tag_dir, "index.html"), tag_html)
        puts "  Generated: /tags/#{tag}/"
      end
    end

    private def copy_static_files
      return unless Dir.exists?(@config.static_dir)

      Dir.glob(File.join(@config.static_dir, "**", "*")).each do |source_path|
        next unless File.file?(source_path)

        relative_path = source_path[@config.static_dir.size + 1..]
        output_path = File.join(@config.output_dir, relative_path)
        output_dir = File.dirname(output_path)

        Dir.mkdir_p(output_dir)
        File.copy(source_path, output_path)
      end

      puts "  Copied static files"
    end

    private def generate_output_path(content : Content) : String
      if content.url == "/"
        File.join(@config.output_dir, "index.html")
      else
        # Remove leading and trailing slashes, add index.html
        clean_url = content.url.strip("/")
        File.join(@config.output_dir, clean_url, "index.html")
      end
    end

    private def generate_default_index(recent_posts : Array(Content)) : String
      posts_html = recent_posts.map do |post|
        date_str = post.date ? post.date.not_nil!.to_s("%B %d, %Y") : ""
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
      </body>
      </html>
      HTML
    end

    private def generate_posts_archive(posts : Array(Content)) : String
      posts_html = posts.map do |post|
        date_str = post.date ? post.date.not_nil!.to_s("%B %d, %Y") : ""
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
        date_str = post.date ? post.date.not_nil!.to_s("%B %d, %Y") : ""

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
      posts = all_content.select(&.is_post_layout?)
      return if posts.empty?

      feed_generator = FeedGenerator.new(@config)

      # Generate RSS feed
      rss_content = feed_generator.generate_rss(posts)
      write_file_atomically(File.join(@config.output_dir, "feed.xml"), rss_content)
      puts "  Generated: /feed.xml"

      # Generate Atom feed
      atom_content = feed_generator.generate_atom(posts)
      write_file_atomically(File.join(@config.output_dir, "feed.atom"), atom_content)
      puts "  Generated: /feed.atom"

      # Generate JSON Feed
      json_content = feed_generator.generate_json_feed(posts)
      write_file_atomically(File.join(@config.output_dir, "feed.json"), json_content)
      puts "  Generated: /feed.json"
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
      recent_posts = all_content.select(&.is_post_layout?).first(count)

      if recent_posts.empty?
        return %(<div class="recent-posts-empty">No posts available yet.</div>)
      end

      posts_html = recent_posts.map do |post|
        date_str = post.date ? post.date.not_nil!.to_s("%B %d, %Y") : ""
        tags_html = post.tags.first(3).map { |tag| %(<span class="tag">#{tag}</span>) }.join(" ")

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
      Logger.debug("Writing file atomically", path: path, size: content.size)

      temp_path = "#{path}.tmp"

      begin
        # Ensure directory exists
        dir = File.dirname(path)
        Dir.mkdir_p(dir) unless Dir.exists?(dir)

        File.open(temp_path, "w") do |file|
          file.set_encoding("UTF-8")
          file.print(content)
          file.flush
        end

        File.rename(temp_path, path)
        Logger.debug("File written successfully", path: path)
      rescue ex : IO::Error
        Logger.error("Failed to write file atomically",
          file: path,
          temp_file: temp_path,
          error: ex.message,
          error_class: ex.class.name)
        File.delete(temp_path) if temp_path && File.exists?(temp_path)
        raise FileSystemError.new("Error writing file #{path}: #{ex.message}", path, "write")
      end
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
      if @config.build_config.parallel && changed_content.size > 1
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
      css_dir = File.join(@config.static_dir, "css")
      if Dir.exists?(css_dir)
        asset_files.concat(Dir.glob(File.join(css_dir, "*.css")))
      end

      # JS files
      js_dir = File.join(@config.static_dir, "js")
      if Dir.exists?(js_dir)
        asset_files.concat(Dir.glob(File.join(js_dir, "*.js")))
      end

      # Image files
      images_dir = File.join(@config.static_dir, "images")
      if Dir.exists?(images_dir)
        asset_files.concat(Dir.glob(File.join(images_dir, "*.{jpg,jpeg,png,gif,svg,webp}")))
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
