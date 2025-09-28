require "../spec_helper"

describe Lapis::FunctionProcessor do
  describe "#process" do
    it "processes site template variables correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.theme = "default"
      config.theme_dir = "themes/default"
      config.baseurl = "http://example.com"
      config.debug = true

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test site template variables
        template = "{{ site.title }} - {{ site.theme }} - {{ site.base_url }} - {{ site.debug }}"
        result = processor.process(template)

        result.should eq("Test Site - default - http://example.com - true")
      end
    end

    it "processes site config template variables correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.theme_dir = "custom/themes/my-theme"
      config.layouts_dir = "custom/layouts"
      config.static_dir = "custom/static"
      config.output_dir = "custom/output"
      config.content_dir = "custom/content"

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test site config template variables
        template = "{{ site.theme_dir }} - {{ site.layouts_dir }} - {{ site.static_dir }} - {{ site.output_dir }} - {{ site.content_dir }}"
        result = processor.process(template)

        result.should eq("custom/themes/my-theme - custom/layouts - custom/static - custom/output - custom/content")
      end
    end

    it "processes page template variables correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content with specific properties
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        frontmatter["layout"] = YAML::Any.new("custom-layout")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test page template variables
        template = "{{ page.title }} - {{ page.layout }} - {{ page.kind }} - {{ page.url }}"
        result = processor.process(template)

        result.should eq("Test Page - custom-layout - single - /test-page/")
      end
    end

    it "processes nested config object template variables correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.build_config.incremental = true
      config.build_config.parallel = true
      config.build_config.cache_dir = ".custom-cache"
      config.build_config.max_workers = 4

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test nested config template variables
        template = "{{ site.build_config.incremental }} - {{ site.build_config.parallel }} - {{ site.build_config.cache_dir }} - {{ site.build_config.max_workers }}"
        result = processor.process(template)

        result.should eq("true - true - .custom-cache - 4")
      end
    end

    it "handles missing template variables gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test missing template variables
        template = "{{ site.nonexistent }} - {{ page.nonexistent }} - {{ nonexistent.variable }}"
        result = processor.process(template)

        # Should return empty strings for missing variables
        result.should eq(" -  - ")
      end
    end

    it "processes debug partial template variables correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Debug Test Site", "debug_output")
      config.theme = "debug-theme"
      config.theme_dir = "../themes/debug-theme"
      config.baseurl = "http://localhost:3000"
      config.debug = true

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Debug Test Page", "debug-test")
        frontmatter["layout"] = YAML::Any.new("debug-layout")
        content = Lapis::Content.new("content/debug-test.md", frontmatter, "Debug test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test debug partial template variables
        debug_template = <<-HTML
        <div><strong>Current Theme:</strong> {{ site.theme }}</div>
        <div><strong>Theme Dir:</strong> {{ site.theme_dir }}</div>
        <div><strong>Title:</strong> {{ site.title }}</div>
        <div><strong>Base URL:</strong> {{ site.base_url }}</div>
        <div><strong>Debug Mode:</strong> {{ site.debug }}</div>
        <div><strong>Layout:</strong> {{ page.layout }}</div>
        <div><strong>URL:</strong> {{ page.url }}</div>
        HTML

        result = processor.process(debug_template)

        result.should contain("Current Theme:</strong> debug-theme")
        result.should contain("Theme Dir:</strong> ../themes/debug-theme")
        result.should contain("Title:</strong> Debug Test Site")
        result.should contain("Base URL:</strong> http://localhost:3000")
        result.should contain("Debug Mode:</strong> true")
        result.should contain("Layout:</strong> debug-layout")
        result.should contain("URL:</strong> /debug-test/")
      end
    end

    it "processes template variables with dot notation correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.live_reload_config.enabled = true
      config.live_reload_config.websocket_path = "/ws"
      config.live_reload_config.debounce_ms = 100
      config.bundling_config.enabled = true
      config.bundling_config.minify = true
      config.bundling_config.source_maps = false
      config.bundling_config.autoprefix = true

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test dot notation template variables
        template = "{{ site.live_reload_config.enabled }} - {{ site.live_reload_config.websocket_path }} - {{ site.bundling_config.enabled }} - {{ site.bundling_config.minify }}"
        result = processor.process(template)

        result.should eq("true - /ws - true - true")
      end
    end

    it "handles case sensitivity correctly for template variables", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test both capitalized and lowercase method names
        template = "{{ site.Title }} - {{ site.title }} - {{ site.BaseURL }} - {{ site.base_url }}"
        result = processor.process(template)

        result.should eq("Test Site - Test Site -  - ")
      end
    end

    it "processes template variables in debug partial context", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Debug Site", "debug_output")
      config.theme = "default"
      config.theme_dir = "../themes/default"
      config.layouts_dir = "layouts"
      config.static_dir = "static"
      config.output_dir = "public"
      config.content_dir = "content"
      config.debug = false

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Debug Page", "debug-page")
        frontmatter["layout"] = YAML::Any.new("default")
        content = Lapis::Content.new("content/debug-page.md", frontmatter, "Debug page content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test the exact debug partial template variables
        debug_template = <<-HTML
        <div class="debug-section">
          <h4>Theme Info</h4>
          <div><strong>Current Theme:</strong> {{ site.theme }}</div>
          <div><strong>Theme Dir:</strong> {{ site.theme_dir }}</div>
          <div><strong>Layouts Dir:</strong> {{ site.layouts_dir }}</div>
          <div><strong>Static Dir:</strong> {{ site.static_dir }}</div>
        </div>
        <div class="debug-section">
          <h4>Site Config</h4>
          <div><strong>Title:</strong> {{ site.title }}</div>
          <div><strong>Base URL:</strong> {{ site.base_url }}</div>
          <div><strong>Output Dir:</strong> {{ site.output_dir }}</div>
          <div><strong>Content Dir:</strong> {{ site.content_dir }}</div>
          <div><strong>Debug Mode:</strong> {{ site.debug }}</div>
        </div>
        <div class="debug-section">
          <h4>Page Info</h4>
          <div><strong>Layout:</strong> {{ page.layout }}</div>
          <div><strong>Kind:</strong> {{ page.kind }}</div>
          <div><strong>URL:</strong> {{ page.url }}</div>
        </div>
        HTML

        result = processor.process(debug_template)

        # Verify all debug partial variables are populated
        result.should contain("Current Theme:</strong> default")
        result.should contain("Theme Dir:</strong> ../themes/default")
        result.should contain("Layouts Dir:</strong> layouts")
        result.should contain("Static Dir:</strong> static")
        result.should contain("Title:</strong> Debug Site")
        result.should contain("Output Dir:</strong> public")
        result.should contain("Content Dir:</strong> content")
        result.should contain("Debug Mode:</strong> false")
        result.should contain("Layout:</strong> default")
        result.should contain("Kind:</strong> single")
        result.should contain("URL:</strong> /debug-page/")
      end
    end

    it "processes function calls correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir

        # Create test content
        frontmatter = TestDataFactory.create_content("Test Page", "test-page")
        content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")

        # Create template context
        context = Lapis::TemplateContext.new(config, content)

        # Create function processor
        processor = Lapis::FunctionProcessor.new(context)

        # Test function calls
        template = "{{ slugify(\"Hello World!\") }} - {{ upper(\"hello\") }} - {{ add(2, 3) }}"
        result = processor.process(template)

        result.should eq("hello-world - HELLO - 5.0")
      end
    end
  end
end
