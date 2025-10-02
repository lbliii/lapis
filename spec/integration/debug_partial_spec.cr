require "../spec_helper"

describe "Debug Partial Integration" do
  describe "debug partial rendering" do
    it "renders debug partial with populated template variables", tags: [TestTags::INTEGRATION] do
      with_temp_directory do |temp_dir|
        # Create test site structure
        content_dir = File.join(temp_dir, "content")
        output_dir = File.join(temp_dir, "output")
        themes_dir = File.join(temp_dir, "themes", "default")
        layouts_dir = File.join(themes_dir, "layouts")
        partials_dir = File.join(layouts_dir, "partials")

        Dir.mkdir_p(content_dir)
        Dir.mkdir_p(output_dir)
        Dir.mkdir_p(partials_dir)

        # Create config with custom theme directory
        config = TestDataFactory.create_config("Debug Test Site", output_dir)
        config.theme = "default"
        config.theme_dir = "../themes/default"
        config.baseurl = "http://localhost:3000"
        config.debug = true
        config.root_dir = temp_dir

        # Create test content
        content_text = <<-MD
        ---
        title: Debug Test Page
        date: 2024-01-15
        layout: default
        ---

        # Debug Test Page

        This page tests the debug partial functionality.
        MD

        File.write(File.join(content_dir, "debug-test.md"), content_text)

        # Create debug partial
        debug_partial = <<-HTML
        <!-- Theme Debug Information -->
        <div id="lapis-debug">
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
        </div>
        HTML

        File.write(File.join(partials_dir, "debug.html"), debug_partial)

        # Create base layout that includes debug partial
        base_layout = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>{{ site.title }}</title>
        </head>
        <body>
          <main>
            <h1>{{ page.title }}</h1>
            <div>{{ content }}</div>
          </main>
          {{ partial "debug" . }}
        </body>
        </html>
        HTML

        File.write(File.join(layouts_dir, "baseof.html"), base_layout)

        # Create default layout
        default_layout = <<-HTML
        {{ partial "baseof" . }}
        HTML

        File.write(File.join(layouts_dir, "default.html"), default_layout)

        # Create template engine with custom theme directory
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "debug-test.md"))

        # Render template
        rendered = template_engine.render_all_formats(content)

        # Should have HTML output
        rendered.keys.should contain("html")
        html_output = rendered["html"]

        # Verify debug partial is included
        html_output.should contain("lapis-debug")
        html_output.should contain("Theme Info")
        html_output.should contain("Site Config")
        html_output.should contain("Page Info")

        # Verify template variables are populated
        html_output.should contain("Current Theme:</strong> default")
        html_output.should contain("Theme Dir:</strong> ../themes/default")
        html_output.should contain("Title:</strong> Debug Test Site")
        html_output.should contain("Base URL:</strong> http://localhost:3000")
        html_output.should contain("Debug Mode:</strong> true")
        html_output.should contain("Layout:</strong> default")
        html_output.should contain("URL:</strong> /debug-test/")

        # Verify page content is rendered
        html_output.should contain("Debug Test Page")
        html_output.should contain("This page tests the debug partial functionality")
      end
    end

    it "handles debug partial with custom theme directory correctly", tags: [TestTags::INTEGRATION] do
      with_temp_directory do |temp_dir|
        # Create test site structure with custom theme directory
        content_dir = File.join(temp_dir, "content")
        output_dir = File.join(temp_dir, "public")
        custom_themes_dir = File.join(temp_dir, "custom", "themes", "my-theme")
        layouts_dir = File.join(custom_themes_dir, "layouts")
        partials_dir = File.join(layouts_dir, "partials")

        Dir.mkdir_p(content_dir)
        Dir.mkdir_p(output_dir)
        Dir.mkdir_p(partials_dir)

        # Create config with custom theme directory
        config = TestDataFactory.create_config("Custom Theme Site", output_dir)
        config.theme = "my-theme"
        config.theme_dir = "../custom/themes/my-theme"
        config.baseurl = "https://example.com"
        config.debug = false
        config.root_dir = temp_dir

        # Create test content
        content_text = <<-MD
        ---
        title: Custom Theme Test
        date: 2024-01-15
        layout: default
        ---

        # Custom Theme Test

        Testing custom theme directory functionality.
        MD

        File.write(File.join(content_dir, "custom-theme-test.md"), content_text)

        # Create debug partial
        debug_partial = <<-HTML
        <div id="lapis-debug">
          <div class="debug-section">
            <h4>Theme Info</h4>
            <div><strong>Current Theme:</strong> {{ site.theme }}</div>
            <div><strong>Theme Dir:</strong> {{ site.theme_dir }}</div>
          </div>
          <div class="debug-section">
            <h4>Site Config</h4>
            <div><strong>Title:</strong> {{ site.title }}</div>
            <div><strong>Base URL:</strong> {{ site.base_url }}</div>
            <div><strong>Debug Mode:</strong> {{ site.debug }}</div>
          </div>
        </div>
        HTML

        File.write(File.join(partials_dir, "debug.html"), debug_partial)

        # Create base layout
        base_layout = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>{{ site.title }}</title>
        </head>
        <body>
          <main>
            <h1>{{ page.title }}</h1>
            <div>{{ content }}</div>
          </main>
          {{ partial "debug" . }}
        </body>
        </html>
        HTML

        File.write(File.join(layouts_dir, "baseof.html"), base_layout)

        # Create default layout
        default_layout = <<-HTML
        {{ partial "baseof" . }}
        HTML

        File.write(File.join(layouts_dir, "default.html"), default_layout)

        # Create template engine with custom theme directory
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "custom-theme-test.md"))

        # Render template
        rendered = template_engine.render_all_formats(content)

        # Should have HTML output
        rendered.keys.should contain("html")
        html_output = rendered["html"]

        # Verify debug partial is included and populated correctly
        html_output.should contain("Current Theme:</strong> my-theme")
        html_output.should contain("Theme Dir:</strong> ../custom/themes/my-theme")
        html_output.should contain("Title:</strong> Custom Theme Site")
        html_output.should contain("Base URL:</strong> https://example.com")
        html_output.should contain("Debug Mode:</strong> false")

        # Verify page content is rendered
        html_output.should contain("Custom Theme Test")
        html_output.should contain("Testing custom theme directory functionality")
      end
    end

    it "handles debug partial in fallback mode correctly", tags: [TestTags::INTEGRATION] do
      with_temp_directory do |temp_dir|
        # Create test site structure without theme
        content_dir = File.join(temp_dir, "content")
        output_dir = File.join(temp_dir, "public")

        Dir.mkdir_p(content_dir)
        Dir.mkdir_p(output_dir)

        # Create config with non-existent theme directory
        config = TestDataFactory.create_config("Fallback Test Site", output_dir)
        config.theme = "nonexistent-theme"
        config.theme_dir = "../nonexistent/themes/theme"
        config.baseurl = "http://fallback.test"
        config.debug = true
        config.root_dir = temp_dir

        # Create test content
        content_text = <<-MD
        ---
        title: Fallback Test Page
        date: 2024-01-15
        ---

        # Fallback Test Page

        This page tests fallback mode functionality.
        MD

        File.write(File.join(content_dir, "fallback-test.md"), content_text)

        # Create template engine (should fall back to default theme)
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "fallback-test.md"))

        # Render template
        rendered = template_engine.render_all_formats(content)

        # Should have HTML output
        rendered.keys.should contain("html")
        html_output = rendered["html"]

        # Verify fallback template is used (should contain debug partial from fallback template)
        html_output.should contain("lapis-debug")
        html_output.should contain("FALLBACK MODE")

        # Verify template variables are populated even in fallback mode
        html_output.should contain("Title:</strong> Fallback Test Site")
        html_output.should contain("Base URL:</strong> http://fallback.test")
        html_output.should contain("Debug Mode:</strong> true")

        # Verify page content is rendered
        html_output.should contain("Fallback Test Page")
        html_output.should contain("This page tests fallback mode functionality")
      end
    end

    it "verifies debug partial template variables don't regress", tags: [TestTags::INTEGRATION] do
      with_temp_directory do |temp_dir|
        # Create test site structure
        content_dir = File.join(temp_dir, "content")
        output_dir = File.join(temp_dir, "public")
        themes_dir = File.join(temp_dir, "themes", "default")
        layouts_dir = File.join(themes_dir, "layouts")
        partials_dir = File.join(layouts_dir, "partials")

        Dir.mkdir_p(content_dir)
        Dir.mkdir_p(output_dir)
        Dir.mkdir_p(partials_dir)

        # Create config with all possible settings
        config = TestDataFactory.create_config("Regression Test Site", output_dir)
        config.theme = "default"
        config.theme_dir = "../themes/default"
        config.layouts_dir = "custom/layouts"
        config.static_dir = "custom/static"
        config.output_dir = "custom/output"
        config.content_dir = "custom/content"
        config.baseurl = "https://regression.test"
        config.debug = true
        config.build_config.incremental = true
        config.build_config.parallel = true
        config.build_config.cache_dir = ".regression-cache"
        config.build_config.max_workers = 8
        config.live_reload_config.enabled = true
        config.live_reload_config.websocket_path = "/ws"
        config.live_reload_config.debounce_ms = 200
        config.bundling_config.enabled = true
        config.bundling_config.minify = true
        config.bundling_config.source_maps = true
        config.bundling_config.autoprefix = true
        config.root_dir = temp_dir

        # Create test content
        content_text = <<-MD
        ---
        title: Regression Test Page
        date: 2024-01-15
        layout: regression-layout
        ---

        # Regression Test Page

        This page tests that all debug partial variables work correctly.
        MD

        File.write(File.join(content_dir, "regression-test.md"), content_text)

        # Create comprehensive debug partial
        debug_partial = <<-HTML
        <div id="lapis-debug">
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
          <div class="debug-section">
            <h4>Build Info</h4>
            <div><strong>Incremental:</strong> {{ site.build_config.incremental }}</div>
            <div><strong>Parallel:</strong> {{ site.build_config.parallel }}</div>
            <div><strong>Cache Dir:</strong> {{ site.build_config.cache_dir }}</div>
            <div><strong>Max Workers:</strong> {{ site.build_config.max_workers }}</div>
          </div>
          <div class="debug-section">
            <h4>Live Reload</h4>
            <div><strong>Enabled:</strong> {{ site.live_reload_config.enabled }}</div>
            <div><strong>WebSocket Path:</strong> {{ site.live_reload_config.websocket_path }}</div>
            <div><strong>Debounce:</strong> {{ site.live_reload_config.debounce_ms }}</div>
          </div>
          <div class="debug-section">
            <h4>Bundling</h4>
            <div><strong>Enabled:</strong> {{ site.bundling_config.enabled }}</div>
            <div><strong>Minify:</strong> {{ site.bundling_config.minify }}</div>
            <div><strong>Source Maps:</strong> {{ site.bundling_config.source_maps }}</div>
            <div><strong>Autoprefix:</strong> {{ site.bundling_config.autoprefix }}</div>
          </div>
        </div>
        HTML

        File.write(File.join(partials_dir, "debug.html"), debug_partial)

        # Create base layout
        base_layout = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>{{ site.title }}</title>
        </head>
        <body>
          <main>
            <h1>{{ page.title }}</h1>
            <div>{{ content }}</div>
          </main>
          {{ partial "debug" . }}
        </body>
        </html>
        HTML

        File.write(File.join(layouts_dir, "baseof.html"), base_layout)

        # Create default layout
        default_layout = <<-HTML
        {{ partial "baseof" . }}
        HTML

        File.write(File.join(layouts_dir, "default.html"), default_layout)

        # Create template engine
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "regression-test.md"))

        # Render template
        rendered = template_engine.render_all_formats(content)

        # Should have HTML output
        rendered.keys.should contain("html")
        html_output = rendered["html"]

        # Verify all debug partial variables are populated correctly
        html_output.should contain("Current Theme:</strong> default")
        html_output.should contain("Theme Dir:</strong> ../themes/default")
        html_output.should contain("Layouts Dir:</strong> custom/layouts")
        html_output.should contain("Static Dir:</strong> custom/static")
        html_output.should contain("Title:</strong> Regression Test Site")
        html_output.should contain("Base URL:</strong> https://regression.test")
        html_output.should contain("Output Dir:</strong> custom/output")
        html_output.should contain("Content Dir:</strong> custom/content")
        html_output.should contain("Debug Mode:</strong> true")
        html_output.should contain("Layout:</strong> regression-layout")
        html_output.should contain("Kind:</strong> page")
        html_output.should contain("URL:</strong> /regression-test/")
        html_output.should contain("Incremental:</strong> true")
        html_output.should contain("Parallel:</strong> true")
        html_output.should contain("Cache Dir:</strong> .regression-cache")
        html_output.should contain("Max Workers:</strong> 8")
        html_output.should contain("Enabled:</strong> true")
        html_output.should contain("WebSocket Path:</strong> /ws")
        html_output.should contain("Debounce:</strong> 200")
        html_output.should contain("Minify:</strong> true")
        html_output.should contain("Source Maps:</strong> true")
        html_output.should contain("Autoprefix:</strong> true")

        # Verify page content is rendered
        html_output.should contain("Regression Test Page")
        html_output.should contain("This page tests that all debug partial variables work correctly")
      end
    end
  end
end
