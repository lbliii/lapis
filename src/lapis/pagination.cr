module Lapis
  class Paginator
    property items : Array(Content)
    property per_page : Int32
    property current_page : Int32
    property base_url : String

    def initialize(@items : Array(Content), @per_page : Int32 = 10, @current_page : Int32 = 1, @base_url : String = "/posts")
    end

    def total_pages : Int32
      (@items.size.to_f / @per_page).ceil.to_i
    end

    def total_items : Int32
      @items.size
    end

    def current_items : Array(Content)
      start_index = (@current_page - 1) * @per_page
      end_index = start_index + @per_page - 1
      @items[start_index..end_index]? || [] of Content
    end

    def has_previous? : Bool
      @current_page > 1
    end

    def has_next? : Bool
      @current_page < total_pages
    end

    def previous_page : Int32?
      has_previous? ? @current_page - 1 : nil
    end

    def next_page : Int32?
      has_next? ? @current_page + 1 : nil
    end

    def previous_url : String?
      if prev_page = previous_page
        prev_page == 1 ? @base_url + "/" : "#{@base_url}/page/#{prev_page}/"
      end
    end

    def next_url : String?
      if next_pg = next_page
        "#{@base_url}/page/#{next_pg}/"
      end
    end

    def page_url(page : Int32) : String
      page == 1 ? @base_url + "/" : "#{@base_url}/page/#{page}/"
    end

    def page_range(window : Int32 = 2) : Array(Int32)
      start_page = [@current_page - window, 1].max
      end_page = [@current_page + window, total_pages].min
      (start_page..end_page).to_a
    end

    def generate_pagination_html : String
      return "" if total_pages <= 1

      nav_items = [] of String

      # Previous button
      if has_previous?
        nav_items << %(<a href="#{previous_url}" class="pagination-prev">← Previous</a>)
      else
        nav_items << %(<span class="pagination-prev disabled">← Previous</span>)
      end

      # Page numbers
      page_range.each do |page|
        if page == @current_page
          nav_items << %(<span class="pagination-current">#{page}</span>)
        else
          nav_items << %(<a href="#{page_url(page)}" class="pagination-page">#{page}</a>)
        end
      end

      # Show ellipsis and last page if needed
      if page_range.last < total_pages - 1
        nav_items << %(<span class="pagination-ellipsis">…</span>)
        nav_items << %(<a href="#{page_url(total_pages)}" class="pagination-page">#{total_pages}</a>)
      elsif page_range.last == total_pages - 1
        nav_items << %(<a href="#{page_url(total_pages)}" class="pagination-page">#{total_pages}</a>)
      end

      # Next button
      if has_next?
        nav_items << %(<a href="#{next_url}" class="pagination-next">Next →</a>)
      else
        nav_items << %(<span class="pagination-next disabled">Next →</span>)
      end

      <<-HTML
      <nav class="pagination">
        <div class="pagination-info">
          Showing #{(@current_page - 1) * @per_page + 1}-#{[@current_page * @per_page, total_items].min} of #{total_items} posts
        </div>
        <div class="pagination-nav">
          #{nav_items.join("\n")}
        </div>
      </nav>
      HTML
    end
  end

  class PaginationGenerator
    property config : Config

    def initialize(@config : Config)
    end

    def generate_paginated_archives(posts : Array(Content), per_page : Int32 = 10)
      total_pages = (posts.size.to_f / per_page).ceil.to_i

      (1..total_pages).each do |page_num|
        paginator = Paginator.new(posts, per_page, page_num, "/posts")
        generate_archive_page(paginator, page_num)
      end

      puts "  Generated: #{total_pages} paginated archive pages"
    end

    def generate_tag_paginated_archives(posts_by_tag : Hash(String, Array(Content)), per_page : Int32 = 10)
      posts_by_tag.each do |tag, tag_posts|
        tag_slug = tag.downcase.gsub(/[^a-z0-9]/, "-")
        total_pages = (tag_posts.size.to_f / per_page).ceil.to_i

        (1..total_pages).each do |page_num|
          paginator = Paginator.new(tag_posts, per_page, page_num, "/tags/#{tag_slug}")
          generate_tag_archive_page(paginator, tag, tag_slug, page_num)
        end
      end
    end

    private def generate_archive_page(paginator : Paginator, page_num : Int32)
      output_dir = if page_num == 1
                     File.join(@config.output_dir, "posts")
                   else
                     File.join(@config.output_dir, "posts", "page", page_num.to_s)
                   end

      Dir.mkdir_p(output_dir)

      posts_html = paginator.current_items.map do |post|
        date_str = post.date ? post.date.not_nil!.to_s("%B %d, %Y") : ""
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

      page_title = page_num == 1 ? "All Posts" : "All Posts - Page #{page_num}"

      html = <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{page_title} - #{@config.title}</title>
        #{generate_css_links}
      </head>
      <body>
        <header>
          <h1>#{page_title}</h1>
          <p><a href="/">← Back to home</a></p>
        </header>

        <main>
          #{posts_html}
          #{paginator.generate_pagination_html}
        </main>
      </body>
      </html>
      HTML

      File.write(File.join(output_dir, "index.html"), html)
    end

    private def generate_tag_archive_page(paginator : Paginator, tag : String, tag_slug : String, page_num : Int32)
      output_dir = if page_num == 1
                     File.join(@config.output_dir, "tags", tag_slug)
                   else
                     File.join(@config.output_dir, "tags", tag_slug, "page", page_num.to_s)
                   end

      Dir.mkdir_p(output_dir)

      posts_html = paginator.current_items.map do |post|
        date_str = post.date ? post.date.not_nil!.to_s("%B %d, %Y") : ""

        <<-HTML
        <article class="post-item">
          <h3><a href="#{post.url}">#{post.title}</a></h3>
          <div class="meta">#{date_str}</div>
          <p>#{post.excerpt}</p>
          <a href="#{post.url}" class="read-more">Read more →</a>
        </article>
        HTML
      end.join("\n")

      page_title = page_num == 1 ? "Posts tagged \"#{tag}\"" : "Posts tagged \"#{tag}\" - Page #{page_num}"

      html = <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{page_title} - #{@config.title}</title>
        #{generate_css_links}
      </head>
      <body>
        <header>
          <h1>#{page_title}</h1>
          <p><a href="/posts/">← All posts</a> | <a href="/">Home</a></p>
        </header>

        <main>
          #{posts_html}
          #{paginator.generate_pagination_html}
        </main>
      </body>
      </html>
      HTML

      File.write(File.join(output_dir, "index.html"), html)
    end

    private def generate_css_links : String
      css_files = [] of String
      
      # Check for CSS files in static directory
      if Dir.exists?(@config.static_dir)
        css_dir = File.join(@config.static_dir, "css")
        if Dir.exists?(css_dir)
          Dir.glob(File.join(css_dir, "*.css")).each do |css_file|
            relative_path = css_file[@config.static_dir.size + 1..]
            css_files << %(<link rel="stylesheet" href="/assets/#{relative_path}">)
          end
        end
      end
      
      # Fallback to common CSS files if none found
      if css_files.empty?
        css_files << %(<link rel="stylesheet" href="/assets/css/style.css">)
      end
      
      css_files.join("\n        ")
    end
  end
end