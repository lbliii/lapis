require "yaml"
require "time"
require "./../logger"

module Lapis
  # Advanced SEO Plugin - Built into Lapis core
  class AdvancedSEOPlugin < Plugin
    property seo_config : SEOConfig

    def initialize(config : Hash(String, YAML::Any))
      super("seo", "2.0.0", config)
      @seo_config = SEOConfig.from_yaml(config)
    end

    def on_before_build(generator : Generator) : Nil
      log_info("Initializing advanced SEO plugin")

      # Validate required SEO config
      validate_seo_config

      # Create SEO output directory
      create_seo_directories(generator)
    end

    def on_after_content_load(generator : Generator, content : Array(Content)) : Nil
      log_debug("Processing #{content.size} content items for SEO optimization")

      # Analyze content for SEO
      analyze_content_seo(content)

      # Generate internal linking suggestions
      generate_internal_links(content)
    end

    def on_before_page_render(generator : Generator, content : Content) : Nil
      # Enhance content with SEO metadata
      enhance_content_metadata(content)

      # Add structured data context
      add_structured_data_context(content)
    end

    def on_after_page_render(generator : Generator, content : Content, rendered : String) : Nil
      # Inject SEO enhancements into rendered HTML
      enhanced_html = inject_seo_enhancements(rendered, content)

      # Note: In a real implementation, this would need to modify the output
      # This could be done through a post-processing pipeline
    end

    def on_after_build(generator : Generator) : Nil
      log_info("Generating SEO artifacts")

      # Generate sitemap
      generate_sitemap(generator) if @seo_config.generate_sitemap

      # Generate robots.txt
      generate_robots_txt(generator) if @seo_config.generate_robots_txt

      # Generate social media cards
      generate_social_cards(generator) if @seo_config.generate_social_cards

      # Generate SEO report
      generate_seo_report(generator) if @seo_config.generate_report
    end

    def on_before_asset_process(generator : Generator, asset_path : String) : Nil
      # Optimize images for SEO
      if image_file?(asset_path)
        optimize_image_for_seo(asset_path)
      end
    end

    def on_after_asset_process(generator : Generator, asset_path : String, output_path : String) : Nil
      # Add image SEO metadata
      if image_file?(asset_path)
        add_image_seo_metadata(asset_path, output_path)
      end
    end

    private def validate_seo_config
      if @seo_config.site_name.empty?
        log_warn("Site name not configured - using default")
        @seo_config.site_name = "My Site"
      end

      if @seo_config.default_image.empty?
        log_warn("Default social image not configured")
      end
    end

    private def create_seo_directories(generator : Generator)
      seo_dir = File.join(generator.config.output_dir, "seo")
      Dir.mkdir_p(seo_dir)

      # Create subdirectories
      Dir.mkdir_p(File.join(seo_dir, "cards"))
      Dir.mkdir_p(File.join(seo_dir, "sitemaps"))
    end

    private def analyze_content_seo(content : Array(Content))
      content.each do |item|
        # Check for missing SEO elements
        issues = [] of String

        issues << "Missing title" if item.title.empty?
        issues << "Missing description" unless item.frontmatter["description"]?
        issues << "Missing keywords" unless item.frontmatter["keywords"]?
        issues << "Content too short" if item.content.size < 300

        if issues.any?
          log_warn("SEO issues found", page: item.title, issues: issues.join(", "))
        end
      end
    end

    private def generate_internal_links(content : Array(Content))
      # Analyze content for internal linking opportunities
      # This would implement sophisticated internal linking suggestions
      log_debug("Analyzing internal linking opportunities")
    end

    private def enhance_content_metadata(content : Content)
      # Auto-generate missing SEO metadata
      unless content.frontmatter["description"]?
        description = generate_description(content.content)
        content.frontmatter["description"] = description
      end

      unless content.frontmatter["keywords"]?
        keywords = extract_keywords(content.content)
        content.frontmatter["keywords"] = keywords.join(", ")
      end

      # Add Open Graph metadata
      content.frontmatter["og_title"] = content.title
      content.frontmatter["og_description"] = content.frontmatter["description"]
      content.frontmatter["og_type"] = determine_og_type(content)
      content.frontmatter["og_image"] = content.frontmatter["image"]? || @seo_config.default_image

      # Add Twitter Card metadata
      content.frontmatter["twitter_card"] = "summary_large_image"
      content.frontmatter["twitter_site"] = @seo_config.twitter_site
      content.frontmatter["twitter_creator"] = @seo_config.twitter_creator
    end

    private def add_structured_data_context(content : Content)
      # Add JSON-LD structured data context
      structured_data = generate_structured_data(content)
      content.frontmatter["structured_data"] = structured_data
    end

    private def inject_seo_enhancements(html : String, content : Content) : String
      # This would inject SEO enhancements into the HTML
      # In a real implementation, this would be done through the template system

      enhanced_html = html

      # Inject canonical URL
      canonical_url = generate_canonical_url(content)
      enhanced_html = inject_canonical_url(enhanced_html, canonical_url)

      # Inject structured data
      if structured_data = content.frontmatter["structured_data"]?
        enhanced_html = inject_structured_data(enhanced_html, structured_data)
      end

      enhanced_html
    end

    private def generate_sitemap(generator : Generator)
      log_info("Generating XML sitemap")

      # Get all content
      content = generator.load_all_content

      # Generate sitemap XML
      sitemap_xml = build_sitemap_xml(content, generator.config)

      # Write sitemap
      sitemap_path = File.join(generator.config.output_dir, "sitemap.xml")
      File.write(sitemap_path, sitemap_xml)

      log_info("Sitemap generated", path: sitemap_path)
    end

    private def generate_robots_txt(generator : Generator)
      log_info("Generating robots.txt")

      robots_content = build_robots_txt(generator.config)

      robots_path = File.join(generator.config.output_dir, "robots.txt")
      File.write(robots_path, robots_content)

      log_info("Robots.txt generated", path: robots_path)
    end

    private def generate_social_cards(generator : Generator)
      log_info("Generating social media cards")

      # This would generate Open Graph and Twitter Card images
      # Could integrate with image generation services
      log_debug("Social card generation not yet implemented")
    end

    private def generate_seo_report(generator : Generator)
      log_info("Generating SEO report")

      # Analyze the entire site and generate an SEO report
      report = analyze_site_seo(generator)

      # Write report
      report_path = File.join(generator.config.output_dir, "seo", "report.html")
      File.write(report_path, report)

      log_info("SEO report generated", path: report_path)
    end

    # Helper methods
    private def generate_description(content : String) : String
      # Extract first meaningful paragraph or generate from content
      sentences = content.split(/[.!?]+/).reject(&.empty?)
      sentences.first? || content[0..150] + "..."
    end

    private def extract_keywords(content : String) : Array(String)
      # Simple keyword extraction (could be enhanced with NLP)
      words = content.downcase.gsub(/[^a-z\s]/, " ").split(/\s+/)
      word_freq = Hash(String, Int32).new(0)

      words.each do |word|
        next if word.size < 3
        word_freq[word] += 1
      end

      # Return top keywords
      word_freq.to_a.sort_by { |_, freq| -freq }[0..9].map(&.[0])
    end

    private def determine_og_type(content : Content) : String
      case content.content_type
      when .article?
        "article"
      when .page?
        "website"
      else
        "article"
      end
    end

    private def generate_structured_data(content : Content) : String
      # Generate JSON-LD structured data
      case content.content_type
      when .article?
        generate_article_structured_data(content)
      when .page?
        generate_webpage_structured_data(content)
      else
        generate_article_structured_data(content)
      end
    end

    private def generate_article_structured_data(content : Content) : String
      {
        "@context":    "https://schema.org",
        "@type":       "Article",
        "headline":    content.title,
        "description": content.frontmatter["description"]? || content.excerpt,
        "author":      {
          "@type": "Person",
          "name":  @seo_config.author_name,
        },
        "publisher": {
          "@type": "Organization",
          "name":  @seo_config.site_name,
          "logo":  {
            "@type": "ImageObject",
            "url":   @seo_config.logo_url,
          },
        },
        "datePublished": content.date.to_s,
        "dateModified":  content.last_modified.to_s,
      }.to_json
    end

    private def generate_webpage_structured_data(content : Content) : String
      {
        "@context":    "https://schema.org",
        "@type":       "WebPage",
        "name":        content.title,
        "description": content.frontmatter["description"]? || content.excerpt,
        "url":         generate_canonical_url(content),
      }.to_json
    end

    private def build_sitemap_xml(content : Array(Content), config : Config) : String
      # Build XML sitemap
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      xml += "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"

      content.each do |item|
        xml += "  <url>\n"
        xml += "    <loc>#{config.baseurl}#{item.url}</loc>\n"
        xml += "    <lastmod>#{item.last_modified.to_s("%Y-%m-%d")}</lastmod>\n"
        xml += "    <changefreq>#{@seo_config.sitemap_changefreq}</changefreq>\n"
        xml += "    <priority>#{@seo_config.sitemap_priority}</priority>\n"
        xml += "  </url>\n"
      end

      xml += "</urlset>"
      xml
    end

    private def build_robots_txt(config : Config) : String
      robots = "User-agent: *\n"
      robots += "Allow: /\n"
      robots += "Disallow: /admin/\n"
      robots += "Disallow: /private/\n"
      robots += "Sitemap: #{config.baseurl}/sitemap.xml\n"
      robots
    end

    private def analyze_site_seo(generator : Generator) : String
      # Generate comprehensive SEO analysis report
      # This would analyze the entire site for SEO issues
      "<html><body><h1>SEO Report</h1><p>SEO analysis report would go here</p></body></html>"
    end

    private def image_file?(path : String) : Bool
      path.downcase.ends_with?(".jpg") ||
        path.downcase.ends_with?(".jpeg") ||
        path.downcase.ends_with?(".png") ||
        path.downcase.ends_with?(".gif") ||
        path.downcase.ends_with?(".webp")
    end

    private def optimize_image_for_seo(path : String)
      # Image optimization for SEO
      log_debug("Optimizing image for SEO", path: path)
    end

    private def add_image_seo_metadata(path : String, output_path : String)
      # Add alt text and other SEO metadata to images
      log_debug("Adding image SEO metadata", path: output_path)
    end

    private def generate_canonical_url(content : Content) : String
      # Generate canonical URL
      "#{@seo_config.site_url}#{content.url}"
    end

    private def inject_canonical_url(html : String, url : String) : String
      # Inject canonical URL into HTML head
      canonical_tag = "<link rel=\"canonical\" href=\"#{url}\">"
      html.gsub("</head>", "  #{canonical_tag}\n</head>")
    end

    private def inject_structured_data(html : String, structured_data : String) : String
      # Inject JSON-LD structured data
      script_tag = "<script type=\"application/ld+json\">\n#{structured_data}\n</script>"
      html.gsub("</head>", "  #{script_tag}\n</head>")
    end
  end

  # SEO Configuration
  class SEOConfig
    include YAML::Serializable

    property enabled : Bool = true
    property site_name : String = "My Site"
    property site_url : String = "https://example.com"
    property author_name : String = "Site Author"
    property logo_url : String = ""
    property default_image : String = ""
    property twitter_site : String = ""
    property twitter_creator : String = ""
    property facebook_app_id : String = ""
    property generate_sitemap : Bool = true
    property generate_robots_txt : Bool = true
    property generate_social_cards : Bool = false
    property generate_report : Bool = false
    property sitemap_changefreq : String = "weekly"
    property sitemap_priority : Float64 = 0.8
    property auto_meta_tags : Bool = true
    property structured_data : Bool = true

    def initialize
    end
  end
end
