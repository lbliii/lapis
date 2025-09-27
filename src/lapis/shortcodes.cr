module Lapis
  class ShortcodeProcessor
    property config : Config
    property asset_manifest : Hash(String, AssetInfo)?

    def initialize(@config : Config, @asset_manifest = nil)
    end

    def process(content : String) : String
      # Process shortcodes in the content
      result = content

      # Image shortcode: {% image "path/to/image.jpg" "Alt text" %}
      result = result.gsub(/\{%\s*image\s+"([^"]+)"\s+"([^"]*)"\s*%\}/) do |match|
        image_path = $1
        alt_text = $2
        generate_responsive_image(image_path, alt_text)
      end

      # YouTube shortcode: {% youtube "video_id" %}
      result = result.gsub(/\{%\s*youtube\s+"([^"]+)"\s*%\}/) do |match|
        video_id = $1
        generate_youtube_embed(video_id)
      end

      # Code block shortcode: {% highlight "language" %}code{% endhighlight %}
      result = result.gsub(/\{%\s*highlight\s+"([^"]+)"\s*%\}(.*?)\{%\s*endhighlight\s*%\}/m) do |match|
        language = $1
        code = $2.strip
        generate_code_block(code, language)
      end

      # Alert shortcode: {% alert "info" %}Content{% endalert %}
      result = result.gsub(/\{%\s*alert\s+"([^"]+)"\s*%\}(.*?)\{%\s*endalert\s*%\}/m) do |match|
        alert_type = $1
        content = $2.strip
        generate_alert(content, alert_type)
      end

      # Gallery shortcode: {% gallery "folder/path" %}
      result = result.gsub(/\{%\s*gallery\s+"([^"]+)"\s*%\}/) do |match|
        folder_path = $1
        generate_image_gallery(folder_path)
      end

      # Quote shortcode: {% quote "Author" "Source" %}Quote text{% endquote %}
      result = result.gsub(/\{%\s*quote\s+"([^"]*)"\s+"([^"]*)"\s*%\}(.*?)\{%\s*endquote\s*%\}/m) do |match|
        author = $1
        source = $2
        quote_text = $3.strip
        generate_quote(quote_text, author, source)
      end

      # Button shortcode: {% button "URL" "Text" "style" %}
      result = result.gsub(/\{%\s*button\s+"([^"]+)"\s+"([^"]+)"\s+"([^"]*)"\s*%\}/) do |match|
        url = $1
        text = $2
        style = $3.empty? ? "primary" : $3
        generate_button(url, text, style)
      end

      # Table of Contents shortcode: {% toc %}
      result = result.gsub(/\{%\s*toc\s*%\}/) do |match|
        generate_toc_placeholder
      end

      # Recent posts shortcode: {% recent_posts 5 %}
      result = result.gsub(/\{%\s*recent_posts\s+(\d+)\s*%\}/) do |match|
        count = $1.to_i
        generate_recent_posts_placeholder(count)
      end

      result
    end

    private def generate_responsive_image(image_path : String, alt_text : String) : String
      # Use the AssetHelpers for responsive images
      base_name = File.basename(image_path, File.extname(image_path))
      ext = File.extname(image_path)
      dir = File.dirname(image_path) == "." ? "" : "#{File.dirname(image_path)}/"

      # Generate srcset
      sizes = [320, 640, 1024, 1920]
      srcset_items = sizes.map do |width|
        "/assets/#{dir}#{base_name}-#{width}w#{ext} #{width}w"
      end

      srcset = srcset_items.join(", ")
      webp_src = "/assets/#{dir}#{base_name}.webp"

      <<-HTML.strip
      <figure class="responsive-image">
        <picture>
          <source srcset="#{webp_src}" type="image/webp">
          <img src="/assets/#{image_path}"
               srcset="#{srcset}"
               sizes="(max-width: 640px) 100vw, (max-width: 1024px) 80vw, 60vw"
               alt="#{alt_text}"
               loading="lazy">
        </picture>
        #{alt_text.empty? ? "" : %(<figcaption>#{alt_text}</figcaption>)}
      </figure>
      HTML
    end

    private def generate_youtube_embed(video_id : String) : String
      <<-HTML.strip
      <div class="youtube-embed">
        <iframe width="560" height="315"
                src="https://www.youtube.com/embed/#{video_id}"
                title="YouTube video player"
                frameborder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
                loading="lazy">
        </iframe>
      </div>
      HTML
    end

    private def generate_code_block(code : String, language : String) : String
      <<-HTML.strip
      <div class="code-block">
        <div class="code-header">
          <span class="language">#{language}</span>
          <button class="copy-button" onclick="copyCode(this)">Copy</button>
        </div>
        <pre><code class="language-#{language}">#{escape_html(code)}</code></pre>
      </div>
      HTML
    end

    private def generate_alert(content : String, alert_type : String) : String
      icon = case alert_type
             when "info"
                "ℹ️"
             when "warning"
                "⚠️"
             when "error", "danger"
                "🚨"
             when "success"
                "✅"
             else
                "📝"
             end

      <<-HTML.strip
      <div class="alert alert-#{alert_type}">
        <div class="alert-icon">#{icon}</div>
        <div class="alert-content">#{content}</div>
      </div>
      HTML
    end

    private def generate_image_gallery(folder_path : String) : String
      # This would scan the static folder for images
      images = [] of String

      gallery_path = File.join(@config.static_dir, folder_path)
      if Dir.exists?(gallery_path)
        Dir.glob(File.join(gallery_path, "*.{jpg,jpeg,png,gif}")).each do |image_file|
          relative_path = image_file[@config.static_dir.size + 1..]
          images << relative_path
        end
      end

      return %(<p class="gallery-error">Gallery folder not found: #{folder_path}</p>) if images.empty?

      image_items = images.map do |image_path|
        alt_text = File.basename(image_path, File.extname(image_path)).humanize
        <<-HTML
        <div class="gallery-item">
          <img src="/assets/#{image_path}"
               alt="#{alt_text}"
               loading="lazy"
               onclick="openLightbox('#{image_path}')">
        </div>
        HTML
      end

      <<-HTML.strip
      <div class="image-gallery">
        #{image_items.join("\n")}
      </div>
      HTML
    end

    private def generate_quote(quote_text : String, author : String, source : String) : String
      <<-HTML.strip
      <blockquote class="custom-quote">
        <p>#{quote_text}</p>
        #{author.empty? ? "" : %(<cite>— #{author}#{source.empty? ? "" : %(<span class="source">, #{source}</span>)}</cite>)}
      </blockquote>
      HTML
    end

    private def generate_button(url : String, text : String, style : String) : String
      <<-HTML.strip
      <a href="#{url}" class="button button-#{style}">#{text}</a>
      HTML
    end

    private def generate_toc_placeholder : String
      # This will be replaced with actual TOC during content processing
      %(<div class="table-of-contents" id="toc-placeholder"></div>)
    end

    private def generate_recent_posts_placeholder(count : Int32) : String
      # This will be replaced with actual recent posts during content processing
      %(<div class="recent-posts" data-count="#{count}"><!-- Recent posts will be inserted here --></div>)
    end

    private def escape_html(text : String) : String
      text.gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub("\"", "&quot;")
          .gsub("'", "&#39;")
    end
  end

  # Extension to the Content class to process shortcodes
  class Content
    def process_shortcodes(processor : ShortcodeProcessor)
      @content = processor.process(@content)
    end
  end
end