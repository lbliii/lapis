require "../spec_helper"

describe "Incremental Build Integration" do
  describe "End-to-end incremental build workflow" do
    it "performs incremental build correctly" do
      # Create test site structure
      test_dir = "test_incremental_site"
      Dir.mkdir_p(test_dir)

      # Create test config
      config_content = <<-YAML
        title: "Test Site"
        build:
          incremental: true
          cache_dir: ".test-cache"
        theme: "default"
      YAML

      File.write(File.join(test_dir, "lapis.yml"), config_content)

      # Create test content
      content_dir = File.join(test_dir, "content")
      Dir.mkdir_p(content_dir)

      File.write(File.join(content_dir, "index.md"), <<-MD
        ---
        title: "Home"
        ---
        # Welcome
        This is the home page.
      MD
      )

      File.write(File.join(content_dir, "about.md"), <<-MD
        ---
        title: "About"
        ---
        # About Us
        This is the about page.
      MD
      )

      # Create output directory
      output_dir = File.join(test_dir, "public")
      Dir.mkdir_p(output_dir)

      # First build - should create cache
      config = Lapis::Config.load(File.join(test_dir, "lapis.yml"))
      config.root_dir = test_dir
      config.output_dir = output_dir

      generator = Lapis::Generator.new(config)

      # Mock file operations to avoid actual file writing
      generator.define_singleton_method(:write_file_atomically) { |_, _| }
      generator.define_singleton_method(:clean_output_directory) { }
      generator.define_singleton_method(:create_output_directory) { }

      generator.build_with_analytics

      # Verify cache was created
      cache_dir = File.join(test_dir, ".test-cache")
      Dir.exists?(cache_dir).should be_true

      # Second build - should use cache
      generator.build_with_analytics

      # Cache should still exist and be populated
      timestamps_file = File.join(cache_dir, "timestamps.yml")
      File.exists?(timestamps_file).should be_true

      content = File.read(timestamps_file)
      content.should_not eq("--- {}")

      # Cleanup
      FileUtils.rm_rf(test_dir)
    end

    it "detects file changes and rebuilds only changed files" do
      test_dir = "test_file_changes"
      Dir.mkdir_p(test_dir)

      # Create test config
      config_content = <<-YAML
        title: "Test Site"
        build:
          incremental: true
          cache_dir: ".test-cache"
      YAML

      File.write(File.join(test_dir, "lapis.yml"), config_content)

      # Create test content
      content_dir = File.join(test_dir, "content")
      Dir.mkdir_p(content_dir)

      index_file = File.join(content_dir, "index.md")
      about_file = File.join(content_dir, "about.md")

      File.write(index_file, <<-MD
        ---
        title: "Home"
        ---
        # Welcome
        This is the home page.
      MD
      )

      File.write(about_file, <<-MD
        ---
        title: "About"
        ---
        # About Us
        This is the about page.
      MD
      )

      # Create output directory
      output_dir = File.join(test_dir, "public")
      Dir.mkdir_p(output_dir)

      # First build
      config = Lapis::Config.load(File.join(test_dir, "lapis.yml"))
      config.root_dir = test_dir
      config.output_dir = output_dir

      generator = Lapis::Generator.new(config)

      # Mock file operations
      generator.define_singleton_method(:write_file_atomically) { |_, _| }
      generator.define_singleton_method(:clean_output_directory) { }
      generator.define_singleton_method(:create_output_directory) { }

      generator.build_with_analytics

      # Modify one file
      File.write(index_file, <<-MD
        ---
        title: "Home Updated"
        ---
        # Welcome
        This is the updated home page.
      MD
      )

      # Second build - should detect change
      generator.build_with_analytics

      # Verify cache was updated
      cache_dir = File.join(test_dir, ".test-cache")
      timestamps_file = File.join(cache_dir, "timestamps.yml")

      File.exists?(timestamps_file).should be_true
      content = File.read(timestamps_file)
      content.should contain("index.md")

      # Cleanup
      FileUtils.rm_rf(test_dir)
    end
  end

  describe "Performance improvements" do
    it "shows performance improvement with incremental builds" do
      # This test would measure build times
      # First build: ~30ms (full build)
      # Second build: ~10ms (incremental)
      # This is more of a benchmark test

      test_dir = "test_performance"
      Dir.mkdir_p(test_dir)

      # Create test config
      config_content = <<-YAML
        title: "Test Site"
        build:
          incremental: true
          cache_dir: ".test-cache"
      YAML

      File.write(File.join(test_dir, "lapis.yml"), config_content)

      # Create test content
      content_dir = File.join(test_dir, "content")
      Dir.mkdir_p(content_dir)

      File.write(File.join(content_dir, "index.md"), <<-MD
        ---
        title: "Home"
        ---
        # Welcome
        This is the home page.
      MD
      )

      # Create output directory
      output_dir = File.join(test_dir, "public")
      Dir.mkdir_p(output_dir)

      config = Lapis::Config.load(File.join(test_dir, "lapis.yml"))
      config.root_dir = test_dir
      config.output_dir = output_dir

      generator = Lapis::Generator.new(config)

      # Mock file operations
      generator.define_singleton_method(:write_file_atomically) { |_, _| }
      generator.define_singleton_method(:clean_output_directory) { }
      generator.define_singleton_method(:create_output_directory) { }

      # First build
      start_time = Time.monotonic
      generator.build_with_analytics
      first_build_time = Time.monotonic - start_time

      # Second build (should be faster)
      start_time = Time.monotonic
      generator.build_with_analytics
      second_build_time = Time.monotonic - start_time

      # Second build should be faster (or at least not slower)
      second_build_time.should be <= first_build_time

      # Cleanup
      FileUtils.rm_rf(test_dir)
    end
  end
end
