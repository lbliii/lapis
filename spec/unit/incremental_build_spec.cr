require "../spec_helper"

describe "Incremental Build System" do
  describe "IncrementalBuilder" do
    it "creates cache directory on initialization" do
      cache_dir = "test_cache"
      builder = IncrementalBuilder.new(cache_dir)

      Dir.exists?(cache_dir).should be_true
      File.exists?(File.join(cache_dir, "timestamps.yml")).should be_true
      File.exists?(File.join(cache_dir, "dependencies.yml")).should be_true
      File.exists?(File.join(cache_dir, "build_cache.yml")).should be_true
    end

    it "detects file changes correctly" do
      builder = IncrementalBuilder.new("test_cache")
      test_file = "test_file.md"

      # Create test file
      File.write(test_file, "initial content")

      # First check - should need rebuild (no cache)
      builder.needs_rebuild?(test_file).should be_true

      # Update timestamp
      builder.update_timestamp(test_file)

      # Second check - should not need rebuild
      builder.needs_rebuild?(test_file).should be_false

      # Modify file
      File.write(test_file, "modified content")

      # Third check - should need rebuild
      builder.needs_rebuild?(test_file).should be_true

      File.delete(test_file)
    end

    it "tracks dependencies correctly" do
      builder = IncrementalBuilder.new("test_cache")

      builder.add_dependency("page.md", "layout.html")
      builder.add_dependency("page.md", "partial.html")

      deps = builder.dependencies["page.md"]?
      deps.should_not be_nil
      deps.not_nil!.should contain("layout.html")
      deps.not_nil!.should contain("partial.html")
    end

    it "saves and loads cache correctly" do
      builder = IncrementalBuilder.new("test_cache")
      test_file = "test_file.md"

      File.write(test_file, "content")
      builder.update_timestamp(test_file)
      builder.cache_build_result(test_file, "rendered content")
      builder.save_cache

      # Create new builder to test loading
      new_builder = IncrementalBuilder.new("test_cache")
      new_builder.file_timestamps[test_file]?.should_not be_nil
      new_builder.build_cache[test_file]?.should eq("rendered content")

      File.delete(test_file)
    end
  end

  describe "Generator incremental build integration" do
    it "uses incremental build when enabled in config" do
      config = Config.new
      config.build_config.incremental = true

      generator = Generator.new(config)

      # Mock the incremental build method to verify it's called
      incremental_called = false
      generator.define_singleton_method(:generate_content_pages_incremental_v2) do |_|
        incremental_called = true
      end

      # Mock other methods to avoid file system operations
      generator.define_singleton_method(:load_all_content) { [] of Content }
      generator.define_singleton_method(:clean_output_directory) { }
      generator.define_singleton_method(:create_output_directory) { }
      generator.define_singleton_method(:generate_index_page) { |_| }
      generator.define_singleton_method(:generate_archive_pages) { |_| }
      generator.define_singleton_method(:generate_feeds) { |_| }

      generator.build_with_analytics

      incremental_called.should be_true
    end

    it "uses regular build when incremental is disabled" do
      config = Config.new
      config.build_config.incremental = false

      generator = Generator.new(config)

      # Mock the regular build method to verify it's called
      regular_called = false
      generator.define_singleton_method(:generate_content_pages) do |_|
        regular_called = true
      end

      # Mock other methods
      generator.define_singleton_method(:load_all_content) { [] of Content }
      generator.define_singleton_method(:clean_output_directory) { }
      generator.define_singleton_method(:create_output_directory) { }
      generator.define_singleton_method(:generate_index_page) { |_| }
      generator.define_singleton_method(:generate_archive_pages) { |_| }
      generator.define_singleton_method(:generate_feeds) { |_| }

      generator.build_with_analytics

      regular_called.should be_true
    end
  end
end
