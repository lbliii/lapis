require "../spec_helper"

describe "Build Workflow" do
  describe "complete build process" do
    it "builds a complete site from scratch", tags: [TestTags::FUNCTIONAL] do
      config = TestDataFactory.create_config("Complete Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create complete site structure
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        # Create posts directory
        posts_dir = File.join(content_dir, "posts")
        Dir.mkdir_p(posts_dir)

        # Create multiple posts
        3.times do |i|
          post_content = <<-MD
          ---
          title: Post #{i + 1}
          date: 2024-01-#{15 + i}
          tags: [test, post#{i + 1}]
          layout: post
          ---

          # Post #{i + 1}

          This is post #{i + 1} for complete site testing.

          ## Features

          - Markdown processing
          - Template rendering
          - Asset processing
          MD

          File.write(File.join(posts_dir, "post-#{i + 1}.md"), post_content)
        end

        # Create pages
        page_content = <<-MD
        ---
        title: About
        layout: page
        ---

        # About

        This is the about page.
        MD

        File.write(File.join(content_dir, "about.md"), page_content)

        # Create home page
        home_content = <<-MD
        ---
        title: Home
        layout: home
        ---

        # Welcome

        Welcome to our site!
        MD

        File.write(File.join(content_dir, "index.md"), home_content)

        # Build complete site
        generator = Lapis::Generator.new(config)
        generator.build

        # Verify all content was processed
        File.exists?(File.join(config.output_dir, "index.html")).should be_true
        File.exists?(File.join(config.output_dir, "about", "index.html")).should be_true

        3.times do |i|
          File.exists?(File.join(config.output_dir, "2024", "01", "#{15 + i}", "post-#{i + 1}", "index.html")).should be_true
        end

        # Verify feeds were generated
        File.exists?(File.join(config.output_dir, "feed.xml")).should be_true
        File.exists?(File.join(config.output_dir, "feed.json")).should be_true
      end
    end

    it "handles build with errors gracefully", tags: [TestTags::FUNCTIONAL] do
      config = TestDataFactory.create_config("Error Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create content with errors
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        # Create invalid content
        invalid_content = <<-MD
        ---
        title: Invalid Post
        date: invalid-date
        layout: nonexistent_layout
        ---

        # Invalid Post

        This post has errors.
        MD

        File.write(File.join(content_dir, "invalid-post.md"), invalid_content)

        # Build should handle errors gracefully
        generator = Lapis::Generator.new(config)

        expect_raises(Lapis::BuildError) do
          generator.build
        end
      end
    end

    it "builds site with different configurations", tags: [TestTags::FUNCTIONAL] do
      config = TestDataFactory.create_config("Config Test Site", "test_output")
      config.debug = true
      config.build_config.incremental = true
      config.build_config.parallel = true

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Config Test
        date: 2024-01-15
        layout: post
        ---

        # Config Test

        This tests different configurations.
        MD

        File.write(File.join(content_dir, "config-test.md"), content_text)

        # Build with different config
        generator = Lapis::Generator.new(config)
        generator.build

        # Verify build completed
        File.exists?(File.join(config.output_dir, "config-test", "index.html")).should be_true
      end
    end
  end

  describe "incremental builds" do
    it "performs incremental builds", tags: [TestTags::FUNCTIONAL] do
      config = TestDataFactory.create_config("Incremental Site", "test_output")
      config.build_config.incremental = true

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Incremental Test
        date: 2024-01-15
        layout: post
        ---

        # Incremental Test

        This tests incremental builds.
        MD

        File.write(File.join(content_dir, "incremental-test.md"), content_text)

        # Build site
        generator = Lapis::Generator.new(config)
        generator.build

        # Verify build completed
        File.exists?(File.join(config.output_dir, "incremental-test", "index.html")).should be_true

        # Second build should be faster (incremental)
        generator.build

        # Verify build still works
        File.exists?(File.join(config.output_dir, "incremental-test", "index.html")).should be_true
      end
    end
  end

  describe "parallel processing" do
    it "processes content in parallel", tags: [TestTags::FUNCTIONAL] do
      config = TestDataFactory.create_config("Parallel Site", "test_output")
      config.build_config.parallel = true

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        # Create multiple content files for parallel processing
        5.times do |i|
          content_text = <<-MD
          ---
          title: Parallel Test #{i + 1}
          date: 2024-01-#{15 + i}
          layout: post
          ---

          # Parallel Test #{i + 1}

          This tests parallel processing.
          MD

          File.write(File.join(content_dir, "parallel-test-#{i + 1}.md"), content_text)
        end

        # Build site
        generator = Lapis::Generator.new(config)
        generator.build

        # Verify all content was processed
        5.times do |i|
          File.exists?(File.join(config.output_dir, "2024", "01", "#{15 + i}", "parallel-test-#{i + 1}", "index.html")).should be_true
        end
      end
    end
  end
end
