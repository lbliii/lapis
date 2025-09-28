require "../spec_helper"

describe "Generator Integration" do
  describe "build process" do
    it "builds site successfully", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")
        config.content_dir = File.join(temp_dir, "content")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        # Create sample content files
        content_text = <<-MD
        ---
        title: Test Post
        date: 2024-01-15
        tags: [test, crystal]
        layout: post
        ---

        # Test Post

        This is a test post for integration testing.
        MD

        File.write(File.join(content_dir, "test-post.md"), content_text)

        # Create generator and build
        generator = Lapis::Generator.new(config)

        # Should not raise error
        generator.build

        # Verify output was created
        # With date-based URLs, the post should be at /2024/01/15/test-post/
        File.exists?(File.join(config.output_dir, "2024", "01", "15", "test-post", "index.html")).should be_true
      end
    end

    it "handles build errors gracefully", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.output_dir = "/invalid/path/that/does/not/exist"

      generator = Lapis::Generator.new(config)

      expect_raises(Lapis::BuildError) do
        generator.build
      end
    end

    it "processes multiple content files", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")
        config.content_dir = File.join(temp_dir, "content")

        # Create test content directory
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        # Create multiple content files
        3.times do |i|
          content_text = <<-MD
          ---
          title: Post #{i + 1}
          date: 2024-01-#{15 + i}
          tags: [test, post#{i + 1}]
          layout: post
          ---

          # Post #{i + 1}

          This is post #{i + 1} for testing.
          MD

          File.write(File.join(content_dir, "post-#{i + 1}.md"), content_text)
        end

        # Create generator and build
        generator = Lapis::Generator.new(config)
        generator.build

        # Verify all posts were processed
        3.times do |i|
          File.exists?(File.join(config.output_dir, "2024", "01", "#{15 + i}", "post-#{i + 1}", "index.html")).should be_true
        end
      end
    end
  end

  describe "template processing" do
    it "processes templates with content", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")
        config.content_dir = File.join(temp_dir, "content")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Template Test
        date: 2024-01-15
        layout: post
        ---

        # Template Test

        This tests template processing.
        MD

        File.write(File.join(content_dir, "template-test.md"), content_text)

        # Create generator and build
        generator = Lapis::Generator.new(config)
        generator.build

        # Verify template was processed
        output_file = File.join(config.output_dir, "2024", "01", "15", "template-test", "index.html")
        File.exists?(output_file).should be_true

        # Check that content was processed
        content = File.read(output_file)
        content.should contain("Template Test")
        content.should contain("This tests template processing")
      end
    end
  end

  describe "asset processing" do
    it "processes assets during build", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")
        config.content_dir = File.join(temp_dir, "content")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Asset Test
        date: 2024-01-15
        layout: post
        ---

        # Asset Test

        This tests asset processing.
        MD

        File.write(File.join(content_dir, "asset-test.md"), content_text)

        # Create generator and build
        generator = Lapis::Generator.new(config)

        # Should not raise error during asset processing
        generator.build

        # Verify build completed
        File.exists?(File.join(config.output_dir, "2024", "01", "15", "asset-test", "index.html")).should be_true
      end
    end
  end
end
