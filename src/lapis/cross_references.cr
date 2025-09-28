require "./content"

module Lapis
  class CrossReferenceEngine
    getter site_content : Array(Content)

    def initialize(@site_content : Array(Content))
    end

    def process_cross_references(content : Content) : String
      processed_body = content.body

      # Process different types of cross-references
      processed_body = process_wiki_links(processed_body)
      processed_body = process_ref_links(processed_body)
      processed_body = process_relref_links(processed_body)

      processed_body
    end

    def find_backlinks(target_content : Content) : Array(Content)
      backlinks = [] of Content

      @site_content.each do |source_content|
        next if source_content == target_content

        if contains_reference_to?(source_content, target_content)
          backlinks << source_content
        end
      end

      backlinks
    end

    private def process_wiki_links(body : String) : String
      # Process [[Page Title]] style links
      body.gsub(/\[\[([^\]]+)\]\]/) do |match|
        link_text = $1

        # Support [[Page Title|Display Text]] format
        parts = link_text.split("|")
        target = parts[0].strip
        display = parts[1]?.try(&.strip) || target

        if target_content = find_content_by_title(target)
          %(<a href="#{target_content.url}">#{display}</a>)
        else
          %(<span class="broken-link">#{display}</span>)
        end
      end
    end

    private def process_ref_links(body : String) : String
      # Process {{< ref "filename" >}} shortcode style links
      body.gsub(/\{\{<\s*ref\s+"([^"]+)"\s*>\}\}/) do |match|
        filename = $1

        if target_content = find_content_by_filename(filename)
          target_content.url
        else
          "#broken-ref-#{filename}"
        end
      end
    end

    private def process_relref_links(body : String) : String
      # Process {{< relref "filename" >}} for relative references
      body.gsub(/\{\{<\s*relref\s+"([^"]+)"\s*>\}\}/) do |match|
        filename = $1

        if target_content = find_content_by_filename(filename)
          target_content.url
        else
          "#broken-relref-#{filename}"
        end
      end
    end

    private def contains_reference_to?(source : Content, target : Content) : Bool
      body = source.body

      # Check for wiki links to target title
      if body.includes?("[[#{target.title}]]") || body.includes?("[[#{target.title}|")
        return true
      end

      # Check for ref/relref links to target filename
      target_filename = File.basename(target.file_path, ".md")
      if body.includes?(%("#{target_filename}")) && (body.includes?("ref ") || body.includes?("relref "))
        return true
      end

      # Check for direct URL references
      if body.includes?(target.url)
        return true
      end

      false
    end

    private def find_content_by_title(title : String) : Content?
      @site_content.find { |c| c.title.downcase == title.downcase }
    end

    private def find_content_by_filename(filename : String) : Content?
      # Remove extension if present
      base_filename = filename.sub(/\.[^.]+$/, "")

      @site_content.find do |c|
        content_filename = File.basename(c.file_path, ".md")
        content_filename.downcase == base_filename.downcase
      end
    end
  end

  class LinkValidation
    getter site_content : Array(Content)

    def initialize(@site_content : Array(Content))
    end

    def validate_internal_links : Array(BrokenLink)
      broken_links = [] of BrokenLink

      @site_content.each do |content|
        broken_links.concat(find_broken_links_in_content(content))
      end

      broken_links
    end

    private def find_broken_links_in_content(content : Content) : Array(BrokenLink)
      broken_links = [] of BrokenLink
      body = content.body

      # Check markdown links [text](url)
      body.scan(/\[([^\]]+)\]\(([^)]+)\)/) do |match|
        link_text = match[1]
        url = match[2]

        next if url.starts_with?("http") # Skip external links
        next if url.starts_with?("#")   # Skip anchor links

        # Clean up relative URLs
        clean_url = url.starts_with?("/") ? url : "/#{url}"

        unless url_exists?(clean_url)
          broken_links << BrokenLink.new(
            source_content: content,
            target_url: clean_url,
            link_text: link_text,
            link_type: "markdown"
          )
        end
      end

      # Check HTML links
      body.scan(/<a[^>]+href=["']([^"']+)["'][^>]*>([^<]*)<\/a>/) do |match|
        url = match[1]
        link_text = match[2]

        next if url.starts_with?("http") # Skip external links
        next if url.starts_with?("#")   # Skip anchor links

        clean_url = url.starts_with?("/") ? url : "/#{url}"

        unless url_exists?(clean_url)
          broken_links << BrokenLink.new(
            source_content: content,
            target_url: clean_url,
            link_text: link_text,
            link_type: "html"
          )
        end
      end

      broken_links
    end

    private def url_exists?(url : String) : Bool
      @site_content.any? { |c| c.url == url }
    end
  end

  struct BrokenLink
    getter source_content : Content
    getter target_url : String
    getter link_text : String
    getter link_type : String

    def initialize(@source_content : Content, @target_url : String, @link_text : String, @link_type : String)
    end
  end
end