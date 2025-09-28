module Lapis
  class Generator
    include GeneratorAnalytics

    property config : Config
    property template_engine : TemplateEngine
    property asset_processor : AssetProcessor

    def initialize(@config : Config)
      @template_engine = TemplateEngine.new(@config)
      @asset_processor = AssetProcessor.new(@config)
    end

    def build
      clean_output_directory
      create_output_directory

      puts "Loading content..."
      all_content = load_all_content

      puts "Generating pages..."
      generate_content_pages(all_content)

      puts "Processing assets with optimization..."
      @asset_processor.process_all_assets

      puts "Generating index and archive pages..."
      generate_index_page(all_content)
      puts "  About to generate section pages..."
      generate_section_pages(all_content)
      puts "  Section pages completed."
      generate_archive_pages(all_content)

      puts "Generating feeds and sitemap..."
      generate_feeds(all_content)
      generate_sitemap(all_content)

      puts "Build completed! Generated #{all_content.size} pages."
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

      # Load pages from content directory
      if Dir.exists?(@config.content_dir)
        Dir.glob(File.join(@config.content_dir, "*.md")).each do |file_path|
          next if File.basename(file_path) == "index.md"
          begin
            page_content = Content.load(file_path, @config.content_dir)
            page_content.process_content(@config)
            content << page_content
          rescue ex
            puts "Warning: Could not load #{file_path}: #{ex.message}"
          end
        end
      end

      # Load posts (but skip _index.md files as they are section pages)
      if Dir.exists?(@config.posts_dir)
        Dir.glob(File.join(@config.posts_dir, "*.md")).each do |file_path|
          next if File.basename(file_path) == "_index.md"  # Skip section pages
          begin
            post_content = Content.load(file_path, @config.content_dir)
            post_content.process_content(@config)
            content << post_content unless post_content.draft
          rescue ex
            puts "Warning: Could not load #{file_path}: #{ex.message}"
          end
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
          File.write(output_path, rendered_content)
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
        File.write(File.join(@config.output_dir, "index.html"), html)
        puts "  Generated: /"
      else
        # Generate default index page
        posts = all_content.select(&.is_post?).first(5)
        html = generate_default_index(posts)
        File.write(File.join(@config.output_dir, "index.html"), html)
        puts "  Generated: / (default)"
      end
    end

    private def generate_section_pages(all_content : Array(Content))
      # Find and generate _index.md section pages
      search_pattern = File.join(@config.content_dir, "**", "_index.md")
      puts "  Generating section pages..."
      Dir.glob(search_pattern).each do |index_path|
        begin
          section_content = Content.load(index_path, @config.content_dir)
          section_content.process_content(@config)

          # Generate all configured output formats for section pages
          format_outputs = @template_engine.render_all_formats(section_content)

          # Determine output directory based on section
          rel_path = Path[index_path].relative_to(Path[@config.content_dir]).to_s
          dir_parts = Path[rel_path].parts[0..-2] # Remove _index.md filename

          if dir_parts.empty?
            # Root _index.md becomes the home page
            output_dir = @config.output_dir
          else
            # Section _index.md goes to /section/ directory
            output_dir = File.join(@config.output_dir, dir_parts.join("/"))
          end

          Dir.mkdir_p(output_dir)

          # Write each format to appropriate file
          format_outputs.each do |format_name, rendered_content|
            format = @config.output_formats.get_format(format_name)
            next unless format

            filename = format.filename
            output_path = File.join(output_dir, filename)
            File.write(output_path, rendered_content)
          end

          section_url = dir_parts.empty? ? "/" : "/#{dir_parts.join("/")}/"
          puts "  Generated: #{section_url} (#{format_outputs.keys.join(", ")}) [section]"
        rescue ex
          puts "Warning: Could not generate section page #{index_path}: #{ex.message}"
        end
      end
    end

    private def generate_archive_pages(all_content : Array(Content))
      posts = all_content.select(&.is_post?)

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
        File.write(File.join(tag_dir, "index.html"), tag_html)
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
      posts = all_content.select(&.is_post?)
      return if posts.empty?

      feed_generator = FeedGenerator.new(@config)

      # Generate RSS feed
      rss_content = feed_generator.generate_rss(posts)
      File.write(File.join(@config.output_dir, "feed.xml"), rss_content)
      puts "  Generated: /feed.xml"

      # Generate Atom feed
      atom_content = feed_generator.generate_atom(posts)
      File.write(File.join(@config.output_dir, "feed.atom"), atom_content)
      puts "  Generated: /feed.atom"

      # Generate JSON Feed
      json_content = feed_generator.generate_json_feed(posts)
      File.write(File.join(@config.output_dir, "feed.json"), json_content)
      puts "  Generated: /feed.json"
    end

    private def generate_sitemap(all_content : Array(Content))
      sitemap_generator = SitemapGenerator.new(@config)
      sitemap_content = sitemap_generator.generate(all_content)
      File.write(File.join(@config.output_dir, "sitemap.xml"), sitemap_content)
      puts "  Generated: /sitemap.xml"
    end

    private def process_recent_posts_shortcodes(html : String, all_content : Array(Content)) : String
      # Process {% recent_posts N %} shortcodes with actual post data
      result = html.gsub(/\{%\s*recent_posts\s+(\d+)\s*%\}/) do |match|
        count = $1.to_i
        generate_recent_posts_html(all_content, count)
      end
      result
    end

    private def generate_recent_posts_html(all_content : Array(Content), count : Int32) : String
      recent_posts = all_content.select(&.is_post?).first(count)

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
  end
end