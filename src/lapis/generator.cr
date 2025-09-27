module Lapis
  class Generator
    property config : Config
    property template_engine : TemplateEngine

    def initialize(@config : Config)
      @template_engine = TemplateEngine.new(@config)
    end

    def build
      clean_output_directory
      create_output_directory

      puts "Loading content..."
      all_content = load_all_content

      puts "Generating pages..."
      generate_content_pages(all_content)

      puts "Copying static files..."
      copy_static_files

      puts "Generating index and archive pages..."
      generate_index_page(all_content)
      generate_archive_pages(all_content)

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
            content << Content.load(file_path)
          rescue ex
            puts "Warning: Could not load #{file_path}: #{ex.message}"
          end
        end
      end

      # Load posts
      if Dir.exists?(@config.posts_dir)
        Dir.glob(File.join(@config.posts_dir, "*.md")).each do |file_path|
          begin
            post_content = Content.load(file_path)
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
        output_path = generate_output_path(content)
        output_dir = File.dirname(output_path)
        Dir.mkdir_p(output_dir)

        html = @template_engine.render(content)
        File.write(output_path, html)

        puts "  Generated: #{content.url}"
      end
    end

    private def generate_index_page(all_content : Array(Content))
      index_path = File.join(@config.content_dir, "index.md")

      if File.exists?(index_path)
        index_content = Content.load(index_path)
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

    private def generate_archive_pages(all_content : Array(Content))
      posts = all_content.select(&.is_post?)

      # Generate posts archive
      if posts.size > 0
        posts_dir = File.join(@config.output_dir, "posts")
        Dir.mkdir_p(posts_dir)

        archive_html = generate_posts_archive(posts)
        File.write(File.join(posts_dir, "index.html"), archive_html)
        puts "  Generated: /posts/ (archive)"

        # Generate tag pages
        generate_tag_pages(posts)
      end
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
  end
end