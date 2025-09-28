require "../spec_helper"

describe "Cache System" do
  describe "Cache file creation" do
    it "creates cache files with proper YAML structure" do
      cache_dir = "test_cache_system"
      builder = Lapis::IncrementalBuilder.new(cache_dir)

      # Add some test data
      test_file = "test.md"
      File.write(test_file, "content")
      builder.update_timestamp(test_file)
      builder.cache_build_result(test_file, "rendered")
      builder.add_dependency(test_file, "layout.html")
      builder.save_cache

      # Verify cache files exist and contain valid YAML
      timestamps_file = File.join(cache_dir, "timestamps.yml")
      dependencies_file = File.join(cache_dir, "dependencies.yml")
      build_cache_file = File.join(cache_dir, "build_cache.yml")

      File.exists?(timestamps_file).should be_true
      File.exists?(dependencies_file).should be_true
      File.exists?(build_cache_file).should be_true

      # Verify YAML is valid
      timestamps_content = File.read(timestamps_file)
      dependencies_content = File.read(dependencies_file)
      build_cache_content = File.read(build_cache_file)

      # Should not be empty
      timestamps_content.should_not eq("--- {}")
      dependencies_content.should_not eq("--- {}")
      build_cache_content.should_not eq("--- {}")

      # Should be valid YAML
      YAML.parse(timestamps_content).should_not be_nil
      YAML.parse(dependencies_content).should_not be_nil
      YAML.parse(build_cache_content).should_not be_nil

      File.delete(test_file)
      FileUtils.rm_rf(cache_dir)
    end

    it "handles empty cache gracefully" do
      cache_dir = "test_empty_cache"
      builder = Lapis::IncrementalBuilder.new(cache_dir)

      # Save empty cache
      builder.save_cache

      # Files should exist but be empty
      timestamps_file = File.join(cache_dir, "timestamps.yml")
      File.exists?(timestamps_file).should be_true

      content = File.read(timestamps_file)
      content.strip.should eq("--- {}")

      FileUtils.rm_rf(cache_dir)
    end

    it "can clear and recreate cache" do
      cache_dir = "test_cache_clear"
      builder = Lapis::IncrementalBuilder.new(cache_dir)

      # Add data
      test_file = "test.md"
      File.write(test_file, "content")
      builder.update_timestamp(test_file)
      builder.save_cache

      # Verify data exists
      builder.file_timestamps.size.should eq(1)

      # Clear cache
      builder.clear_cache

      # Verify cache is cleared
      builder.file_timestamps.size.should eq(0)
      builder.dependencies.size.should eq(0)
      builder.build_cache.size.should eq(0)

      # Cache directory should still exist but be empty
      Dir.exists?(cache_dir).should be_true

      File.delete(test_file)
      FileUtils.rm_rf(cache_dir)
    end
  end

  describe "Cache directory management" do
    it "creates cache directory if it doesn't exist" do
      cache_dir = "nonexistent_cache_dir"

      Dir.exists?(cache_dir).should be_false

      builder = Lapis::IncrementalBuilder.new(cache_dir)

      Dir.exists?(cache_dir).should be_true

      FileUtils.rm_rf(cache_dir)
    end

    it "handles cache directory permissions correctly" do
      cache_dir = "test_permissions"
      builder = Lapis::IncrementalBuilder.new(cache_dir)

      # Should be able to write files
      test_file = "test.md"
      File.write(test_file, "content")
      builder.update_timestamp(test_file)
      builder.save_cache

      # Should be able to read files back
      new_builder = Lapis::IncrementalBuilder.new(cache_dir)
      new_builder.file_timestamps[test_file]?.should_not be_nil

      File.delete(test_file)
      FileUtils.rm_rf(cache_dir)
    end
  end
end
