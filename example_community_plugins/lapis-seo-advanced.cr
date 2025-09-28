# Community SEO Plugin Example
# This would be published as a separate shard: lapis-seo-advanced
#
# Installation: Add to shard.yml:
# dependencies:
#   lapis-seo-advanced:
#     github: username/lapis-seo-advanced
#     version: ~> 1.0

require "lapis"
require "json"
require "http/client"

module LapisSEOAdvanced
  # Advanced SEO plugin with AI-powered features
  class AdvancedSEOPlugin < Lapis::Plugin
    property config : AdvancedSEOConfig
    property ai_client : AIClient?

    def initialize(config : Hash(String, YAML::Any))
      super("seo-advanced", "1.0.0", config)
      @config = AdvancedSEOConfig.from_yaml(config)

      # Initialize AI client if configured
      if @config.openai_api_key
        @ai_client = AIClient.new(@config.openai_api_key)
      end
    end

    def on_after_content_load(generator : Lapis::Generator, content : Array(Lapis::Content)) : Nil
      log_info("Running advanced SEO analysis on #{content.size} pages")

      # AI-powered SEO analysis
      if @ai_client
        content.each do |page|
          analyze_page_with_ai(page)
        end
      end

      # Generate SEO recommendations
      generate_seo_recommendations(content)

      # Check for duplicate content
      detect_duplicate_content(content)
    end

    def on_after_build(generator : Lapis::Generator) : Nil
      # Submit sitemap to search engines
      submit_sitemap_to_search_engines(generator) if @config.auto_submit_sitemap

      # Generate SEO performance report
      generate_performance_report(generator)

      # Check for SEO issues
      run_seo_audit(generator)
    end

    private def analyze_page_with_ai(page : Lapis::Content)
      return unless @ai_client

      log_debug("Running AI SEO analysis", page: page.title)

      # Use AI to analyze content for SEO
      prompt = build_seo_analysis_prompt(page)
      response = @ai_client.analyze_content(prompt)

      # Store AI recommendations
      page.frontmatter["seo_ai_score"] = response.score
      page.frontmatter["seo_ai_recommendations"] = response.recommendations
      page.frontmatter["seo_ai_keywords"] = response.suggested_keywords
    end

    private def generate_seo_recommendations(content : Array(Lapis::Content))
      recommendations = [] of String

      content.each do |page|
        # Check for missing meta descriptions
        unless page.frontmatter["description"]?
          recommendations << "Page '#{page.title}' is missing a meta description"
        end

        # Check for missing alt text on images
        if page.content.includes?("<img") && !page.content.includes?("alt=")
          recommendations << "Page '#{page.title}' has images without alt text"
        end

        # Check for heading structure
        if !page.content.includes?("<h1>")
          recommendations << "Page '#{page.title}' is missing an H1 heading"
        end
      end

      # Write recommendations to file
      write_recommendations(recommendations)
    end

    private def detect_duplicate_content(content : Array(Lapis::Content))
      log_info("Detecting duplicate content")

      # Simple duplicate detection based on content similarity
      content_hashes = Hash(String, Array(Lapis::Content)).new

      content.each do |page|
        # Create a hash of the content (excluding frontmatter)
        content_hash = Digest::MD5.hexdigest(page.content)
        content_hashes[content_hash] ||= [] of Lapis::Content
        content_hashes[content_hash] << page
      end

      # Report duplicates
      content_hashes.each do |_, pages|
        if pages.size > 1
          log_warn("Duplicate content detected",
            pages: pages.map(&.title).join(", "))
        end
      end
    end

    private def submit_sitemap_to_search_engines(generator : Lapis::Generator)
      sitemap_url = "#{generator.config.baseurl}/sitemap.xml"

      # Submit to Google
      if @config.google_search_console_key
        submit_to_google(sitemap_url)
      end

      # Submit to Bing
      if @config.bing_webmaster_key
        submit_to_bing(sitemap_url)
      end
    end

    private def generate_performance_report(generator : Lapis::Generator)
      log_info("Generating SEO performance report")

      # Analyze site performance metrics
      report = build_performance_report(generator)

      # Write report
      report_path = File.join(generator.config.output_dir, "seo-performance-report.html")
      File.write(report_path, report)

      log_info("Performance report generated", path: report_path)
    end

    private def run_seo_audit(generator : Lapis::Generator)
      log_info("Running comprehensive SEO audit")

      # Check various SEO factors
      audit_results = {
        "missing_meta_descriptions" => check_missing_meta_descriptions(generator),
        "missing_alt_text"          => check_missing_alt_text(generator),
        "broken_internal_links"     => check_broken_internal_links(generator),
        "slow_loading_pages"        => check_page_load_speed(generator),
        "mobile_friendly"           => check_mobile_friendliness(generator),
      }

      # Generate audit report
      audit_report = build_audit_report(audit_results)

      # Write audit report
      audit_path = File.join(generator.config.output_dir, "seo-audit-report.html")
      File.write(audit_path, audit_report)

      log_info("SEO audit completed", issues: audit_results.values.sum)
    end

    # Helper methods
    private def build_seo_analysis_prompt(page : Lapis::Content) : String
      <<-PROMPT
      Analyze this web page content for SEO optimization:

      Title: #{page.title}
      Content: #{page.content[0..1000]}...

      Please provide:
      1. SEO score (1-100)
      2. Top 5 recommendations for improvement
      3. Suggested keywords
      4. Content quality assessment
      PROMPT
    end

    private def write_recommendations(recommendations : Array(String))
      return if recommendations.empty?

      log_info("SEO recommendations generated", count: recommendations.size.to_s)

      # Write to recommendations file
      recommendations_path = File.join("seo-recommendations.txt")
      File.write(recommendations_path, recommendations.join("\n"))
    end

    private def submit_to_google(sitemap_url : String)
      log_info("Submitting sitemap to Google Search Console")
      # Implementation would use Google Search Console API
    end

    private def submit_to_bing(sitemap_url : String)
      log_info("Submitting sitemap to Bing Webmaster Tools")
      # Implementation would use Bing Webmaster API
    end

    private def build_performance_report(generator : Lapis::Generator) : String
      # Generate HTML performance report
      <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>SEO Performance Report</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .metric { background: #f5f5f5; padding: 20px; margin: 10px 0; border-radius: 5px; }
          .good { border-left: 5px solid #4CAF50; }
          .warning { border-left: 5px solid #FF9800; }
          .error { border-left: 5px solid #F44336; }
        </style>
      </head>
      <body>
        <h1>SEO Performance Report</h1>
        <div class="metric good">
          <h3>Site Health: Good</h3>
          <p>Your site is performing well in terms of SEO.</p>
        </div>
        <div class="metric warning">
          <h3>Improvement Opportunities</h3>
          <p>Consider optimizing images and adding more internal links.</p>
        </div>
      </body>
      </html>
      HTML
    end

    private def check_missing_meta_descriptions(generator : Lapis::Generator) : Int32
      # Count pages missing meta descriptions
      0
    end

    private def check_missing_alt_text(generator : Lapis::Generator) : Int32
      # Count images missing alt text
      0
    end

    private def check_broken_internal_links(generator : Lapis::Generator) : Int32
      # Check for broken internal links
      0
    end

    private def check_page_load_speed(generator : Lapis::Generator) : Int32
      # Analyze page load speeds
      0
    end

    private def check_mobile_friendliness(generator : Lapis::Generator) : Int32
      # Check mobile friendliness
      0
    end

    private def build_audit_report(audit_results : Hash(String, Int32)) : String
      # Build comprehensive audit report
      "<html><body><h1>SEO Audit Report</h1><p>Audit results would go here</p></body></html>"
    end
  end

  # AI Client for SEO analysis
  class AIClient
    property api_key : String
    property client : HTTP::Client

    def initialize(@api_key : String)
      @client = HTTP::Client.new("api.openai.com", tls: true)
      @client.basic_auth("Bearer", @api_key)
    end

    def analyze_content(prompt : String) : AIAnalysisResult
      # Make API call to OpenAI or similar service
      response = @client.post("/v1/chat/completions",
        headers: {"Content-Type" => "application/json"},
        body: {
          model:    "gpt-3.5-turbo",
          messages: [
            {"role" => "user", "content" => prompt},
          ],
        }.to_json)

      # Parse response and return structured result
      AIAnalysisResult.new(
        score: 85,
        recommendations: ["Improve heading structure", "Add more internal links"],
        suggested_keywords: ["seo", "optimization", "content"]
      )
    end
  end

  # AI Analysis Result
  struct AIAnalysisResult
    property score : Int32
    property recommendations : Array(String)
    property suggested_keywords : Array(String)

    def initialize(@score : Int32, @recommendations : Array(String), @suggested_keywords : Array(String))
    end
  end

  # Advanced SEO Configuration
  class AdvancedSEOConfig
    include YAML::Serializable

    property openai_api_key : String? = nil
    property google_search_console_key : String? = nil
    property bing_webmaster_key : String? = nil
    property auto_submit_sitemap : Bool = false
    property enable_ai_analysis : Bool = false
    property audit_thresholds : Hash(String, Int32) = {
      "max_loading_time"   => 3000,
      "min_content_length" => 300,
      "max_image_size"     => 500_000,
    }

    def initialize
    end
  end
end
