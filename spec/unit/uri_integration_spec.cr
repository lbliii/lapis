require "../spec_helper"
require "../../src/lapis/*"

describe "URI Integration" do
  describe "Site URI handling" do
    it "parses and caches base URL correctly" do
      config = Lapis::Config.new
      config.baseurl = "https://example.com/path/"
      site = Lapis::Site.new(config)

      # Test cached parsing
      site.base_url_scheme.should eq("https")
      site.base_url_host.should eq("example.com")
      site.base_url_port.should eq(443)
      site.base_url_path.should eq("/path/")
      site.base_url_normalized.should eq("https://example.com/path/")
    end

    it "handles URLs without explicit ports" do
      config = Lapis::Config.new
      config.baseurl = "http://example.com"
      site = Lapis::Site.new(config)

      site.base_url_scheme.should eq("http")
      site.base_url_port.should eq(80)
    end

    it "validates base URLs correctly" do
      config = Lapis::Config.new
      config.baseurl = "https://example.com"
      site = Lapis::Site.new(config)

      site.validate_base_url.should be_true

      config.baseurl = "invalid-url"
      site = Lapis::Site.new(config)
      site.validate_base_url.should be_false
    end

    it "resolves relative URLs correctly" do
      config = Lapis::Config.new
      config.baseurl = "https://example.com/blog/"
      site = Lapis::Site.new(config)

      site.resolve_url("/post/").should eq("https://example.com/post/")
      site.resolve_url("post/").should eq("https://example.com/blog/post/")
    end

    it "relativizes absolute URLs correctly" do
      config = Lapis::Config.new
      config.baseurl = "https://example.com/blog/"
      site = Lapis::Site.new(config)

      site.relativize_url("https://example.com/blog/post/").should eq("post/")
      site.relativize_url("https://example.com/post/").should eq("../post/")
    end
  end

  describe "URI Functions" do
    before_each do
      Lapis::Functions.setup
    end

    it "handles url_normalize function" do
      result = Lapis::Functions.call("url_normalize", ["HTTP://EXAMPLE.COM:80/./foo/../bar/"])
      result.should eq("http://example.com/bar/")
    end

    it "handles url_scheme function" do
      Lapis::Functions.call("url_scheme", ["https://example.com"]).should eq("https")
      Lapis::Functions.call("url_scheme", ["example.com"]).should eq("")
    end

    it "handles url_host function" do
      Lapis::Functions.call("url_host", ["https://example.com"]).should eq("example.com")
      Lapis::Functions.call("url_host", ["/path"]).should eq("")
    end

    it "handles url_port function" do
      Lapis::Functions.call("url_port", ["https://example.com:8080"]).should eq("8080")
      Lapis::Functions.call("url_port", ["https://example.com"]).should eq("")
    end

    it "handles url_path function" do
      Lapis::Functions.call("url_path", ["https://example.com/path/to/page"]).should eq("/path/to/page")
      Lapis::Functions.call("url_path", ["https://example.com"]).should eq("")
    end

    it "handles url_query function" do
      Lapis::Functions.call("url_query", ["https://example.com?param=value"]).should eq("param=value")
      Lapis::Functions.call("url_query", ["https://example.com"]).should eq("")
    end

    it "handles url_fragment function" do
      Lapis::Functions.call("url_fragment", ["https://example.com#section"]).should eq("section")
      Lapis::Functions.call("url_fragment", ["https://example.com"]).should eq("")
    end

    it "handles is_absolute_url function" do
      Lapis::Functions.call("is_absolute_url", ["https://example.com"]).should eq("true")
      Lapis::Functions.call("is_absolute_url", ["/path"]).should eq("false")
    end

    it "handles is_valid_url function" do
      Lapis::Functions.call("is_valid_url", ["https://example.com"]).should eq("true")
      Lapis::Functions.call("is_valid_url", ["invalid-url"]).should eq("false")
    end

    it "handles url_join function" do
      Lapis::Functions.call("url_join", ["https://example.com", "path"]).should eq("https://example.com/path")
      Lapis::Functions.call("url_join", ["https://example.com/", "path"]).should eq("https://example.com/path")
    end

    it "handles url_components function" do
      result = Lapis::Functions.call("url_components", ["https://user:pass@example.com:8080/path?query=value#frag"])
      components = JSON.parse(result).as_h

      components["scheme"].should eq("https")
      components["host"].should eq("example.com")
      components["port"].should eq(8080)
      components["path"].should eq("/path")
      components["query"].should eq("query=value")
      components["fragment"].should eq("frag")
      components["user"].should eq("user")
      components["password"].should eq("***")
    end

    it "handles query_params function" do
      result = Lapis::Functions.call("query_params", ["https://example.com?a=1&b=2"])
      params = JSON.parse(result).as_h
      params["a"].should eq("1")
      params["b"].should eq("2")
    end

    it "handles update_query_param function" do
      result = Lapis::Functions.call("update_query_param", ["https://example.com", "new", "value"])
      result.should eq("https://example.com?new=value")
    end

    it "handles relative_url function with URI methods" do
      result = Lapis::Functions.call("relative_url", ["/post/", "https://example.com/blog/"])
      result.should eq("/post/")
    end

    it "handles absolute_url function with URI methods" do
      result = Lapis::Functions.call("absolute_url", ["/post/", "https://example.com/blog/"])
      result.should eq("https://example.com/post/")
    end
  end

  describe "Template Helpers" do
    it "handles url_for with URI resolution" do
      result = Lapis::TemplateHelpers.url_for("/post/", "https://example.com/blog/")
      result.should eq("https://example.com/post/")
    end

    it "handles relative_url_for with URI relativization" do
      result = Lapis::TemplateHelpers.relative_url_for("/post/", "https://example.com/blog/")
      result.should eq("/post/")
    end

    it "handles normalize_url" do
      result = Lapis::TemplateHelpers.normalize_url("HTTP://EXAMPLE.COM:80/./foo/../bar/")
      result.should eq("http://example.com/bar/")
    end

    it "handles url_components" do
      result = Lapis::TemplateHelpers.url_components("https://example.com:8080/path?q=1#frag")

      result["scheme"].should eq("https")
      result["host"].should eq("example.com")
      result["port"].should eq(8080)
      result["path"].should eq("/path")
      result["query"].should eq("q=1")
      result["fragment"].should eq("frag")
    end
  end

  describe "Content URL Generation" do
    it "generates URLs using URI.resolve" do
      content = Lapis::Content.new(
        file_path: "content/test.md",
        frontmatter: {} of String => YAML::Any,
        body: "Test content"
      )

      url = content.url
      # Should generate URL based on filename
      url.should eq("/test/")
    end
  end

  describe "Config URI Validation" do
    it "validates correct URLs" do
      config = Lapis::Config.new
      config.baseurl = "https://example.com"

      # Should not raise for valid URLs
      config.validate_urls!
    end

    it "rejects invalid URLs" do
      config = Lapis::Config.new
      config.baseurl = "not-a-url"

      expect_raises(Exception, "Configuration error") do
        config.validate_urls!
      end
    end

    it "rejects opaque URLs" do
      config = Lapis::Config.new
      config.baseurl = "mailto:test@example.com"

      expect_raises(Exception, "Configuration error") do
        config.validate_urls!
      end
    end
  end

  describe "Edge Cases" do
    it "handles empty URLs gracefully" do
      Lapis::Functions.call("is_valid_url", [""]).should eq("false")
      Lapis::Functions.call("url_scheme", [""]).should eq("")
    end

    it "handles URLs with special characters" do
      encoded = Lapis::Functions.call("url_encode", ["hello world!"])
      encoded.should eq("hello%20world%21")

      decoded = Lapis::Functions.call("url_decode", ["hello%20world!"])
      decoded.should eq("hello world!")
    end

    it "handles malformed URLs in functions" do
      # Should not raise, but return empty or default values
      Lapis::Functions.call("url_scheme", ["://invalid"]).should eq("")
      Lapis::Functions.call("is_valid_url", ["://invalid"]).should eq("false")
    end

    it "handles IPv6 URLs" do
      result = Lapis::Functions.call("url_host", ["http://[::1]/bar"])
      result.should eq("[::1]")
    end

    it "handles URLs with authentication" do
      result = Lapis::Functions.call("url_components", ["http://user:pass@example.com"])
      components = JSON.parse(result).as_h
      components["user"].should eq("user")
      components["password"].should eq("***")
    end
  end

  describe "Performance" do
    it "caches parsed URIs efficiently" do
      config = Lapis::Config.new
      config.baseurl = "https://example.com"
      site = Lapis::Site.new(config)

      # Multiple calls should use cached parsing
      start_time = Time.monotonic
      1000.times do
        site.base_url_scheme
        site.base_url_host
        site.base_url_port
      end
      elapsed = Time.monotonic - start_time

      # Should be very fast due to caching
      elapsed.total_milliseconds.should be < 10
    end
  end
end
