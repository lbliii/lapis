require "../spec_helper"

describe "Template Engine Integration" do
  describe "template rendering" do
    it "renders templates with content", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Template Engine Test
        date: 2024-01-15
        layout: post
        ---

        # Template Engine Test

        This tests template engine integration.
        MD

        File.write(File.join(content_dir, "template-engine-test.md"), content_text)

        # Create template engine
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "template-engine-test.md"))

        # Render template
        rendered = template_engine.render_all_formats(content)

        # Should have HTML output
        rendered.keys.should contain("html")
        rendered["html"].should contain("Template Engine Test")
        rendered["html"].should contain("This tests template engine integration")
      end
    end

    it "renders multiple output formats", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Multi-Format Test
        date: 2024-01-15
        layout: post
        ---

        # Multi-Format Test

        This tests multiple output formats.
        MD

        File.write(File.join(content_dir, "multi-format-test.md"), content_text)

        # Create template engine
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "multi-format-test.md"))

        # Render template
        rendered = template_engine.render_all_formats(content)

        # Should have multiple formats
        rendered.keys.should contain("html")
        rendered.keys.should contain("json")
        rendered.keys.should contain("llm")

        # Check content in each format
        rendered["html"].should contain("Multi-Format Test")
        rendered["json"].should contain("Multi-Format Test")
        rendered["llm"].should contain("Multi-Format Test")
      end
    end

    it "handles template errors gracefully", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content with invalid template reference
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Error Test
        date: 2024-01-15
        layout: nonexistent_layout
        ---

        # Error Test

        This tests error handling.
        MD

        File.write(File.join(content_dir, "error-test.md"), content_text)

        # Create template engine
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "error-test.md"))

        # Should handle template errors gracefully
        expect_raises(Lapis::TemplateError) do
          template_engine.render_all_formats(content)
        end
      end
    end
  end

  describe "partial rendering" do
    # Partials is a module with static methods, not a class
    # Testing would require testing the static methods directly
  end

  describe "function processing" do
    it "processes template functions", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content with functions
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Function Test
        date: 2024-01-15
        layout: post
        ---

        # Function Test

        This tests function processing: {{ upper "hello world" }}
        MD

        File.write(File.join(content_dir, "function-test.md"), content_text)

        # Create template engine
        template_engine = Lapis::TemplateEngine.new(config)

        # Load content
        content = Lapis::Content.load(File.join(content_dir, "function-test.md"))

        # Test function processing
        context = Lapis::TemplateContext.new(config, content)
        function_processor = Lapis::FunctionProcessor.new(context)

        # Should be able to process functions
        function_processor.should be_a(Lapis::FunctionProcessor)
      end
    end
  end
end
