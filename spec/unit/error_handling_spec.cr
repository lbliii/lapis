require "../spec_helper"
require "../../src/lapis/incremental_builder"

describe "Error Handling" do
  describe "File system errors" do
    it "handles file writing errors gracefully" do
      cache_dir = "test_file_errors"
      builder = Lapis::IncrementalBuilder.new(cache_dir)

      # Test with non-existent file
      builder.needs_rebuild?("nonexistent_file.md").should be_true

      # Test with file that can't be read
      # This would require creating a file with restricted permissions
      # For now, just test that the method doesn't crash

      FileUtils.rm_rf(cache_dir)
    end

    it "handles cache directory creation errors" do
      # Test with invalid cache directory name
      expect_raises(Exception) do
        Lapis::IncrementalBuilder.new("/invalid/path/that/does/not/exist")
      end
    end
  end

  describe "Cache corruption handling" do
    it "handles corrupted cache files gracefully" do
      cache_dir = "test_corrupted_cache"
      Dir.mkdir_p(cache_dir)

      # Create corrupted cache files
      File.write(File.join(cache_dir, "timestamps.yml"), "invalid yaml content")
      File.write(File.join(cache_dir, "dependencies.yml"), "also invalid")
      File.write(File.join(cache_dir, "build_cache.yml"), "corrupted")

      # Should not crash when loading corrupted cache
      builder = Lapis::IncrementalBuilder.new(cache_dir)

      # Should have empty cache after loading corrupted files
      builder.file_timestamps.size.should eq(0)
      builder.dependencies.size.should eq(0)
      builder.build_cache.size.should eq(0)

      FileUtils.rm_rf(cache_dir)
    end

    it "handles missing cache files gracefully" do
      cache_dir = "test_missing_cache"
      Dir.mkdir_p(cache_dir)

      # Don't create any cache files
      builder = Lapis::IncrementalBuilder.new(cache_dir)

      # Should not crash and should have empty cache
      builder.file_timestamps.size.should eq(0)
      builder.dependencies.size.should eq(0)
      builder.build_cache.size.should eq(0)

      FileUtils.rm_rf(cache_dir)
    end
  end

  describe "Configuration errors" do
    it "handles missing config file gracefully" do
      config = Lapis::Config.load("nonexistent_config.yml")

      # Should use default values
      config.title.should eq("Lapis Site")
      config.build_config.incremental.should be_true
    end

    it "handles invalid config values gracefully" do
      invalid_config = <<-YAML
        title: "Test"
        build:
          incremental: "not_a_boolean"
          max_workers: "not_a_number"
      YAML

      File.write("invalid_config.yml", invalid_config)

      # Should handle invalid values gracefully and use defaults
      config = Lapis::Config.load("invalid_config.yml")
      config.title.should eq("Test")                 # Valid value should be used
      config.build_config.incremental.should be_true # Invalid value should fall back to default

      File.delete("invalid_config.yml")
    end

    it "handles TypeCastError in config processing", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that TypeCastError is handled gracefully in config processing
      invalid_config = <<-YAML
        title: "Test"
        build:
          incremental: "not_a_boolean"
          max_workers: "not_a_number"
        theme:
          name: "test-theme"
          config:
            colors:
              primary: "not_a_color_object"
      YAML

      File.write("invalid_config.yml", invalid_config)

      # Should handle type casting errors gracefully
      config = Lapis::Config.load("invalid_config.yml")
      config.title.should eq("Test")

      # Invalid values should fall back to defaults without crashing
      config.build_config.incremental.should be_true

      File.delete("invalid_config.yml")
    end
  end

  describe "Channel errors" do
    it "handles channel closed errors", tags: [TestTags::FAST, TestTags::UNIT] do
      channel = Channel(String).new(1)
      channel.close

      expect_raises(Channel::ClosedError) do
        channel.send("test")
      end
    end

    it "handles channel timeout errors", tags: [TestTags::FAST, TestTags::UNIT] do
      channel = Channel(String).new(1)

      # Test timeout on receive
      result = select
      when r = channel.receive
        r
      when timeout(10.milliseconds)
        "timeout"
      end

      result.should eq("timeout")
    end
  end

  describe "Build process errors" do
    it "handles build failures gracefully" do
      test_dir = "test_build_errors"
      Dir.mkdir_p(test_dir)

      # Create config with invalid settings
      config_content = <<-YAML
        title: "Test Site"
        build:
          incremental: true
          cache_dir: ".test-cache"
        output_dir: "/invalid/output/path"
      YAML

      File.write(File.join(test_dir, "lapis.yml"), config_content)

      config = Lapis::Config.load(File.join(test_dir, "lapis.yml"))
      config.root_dir = test_dir

      generator = Lapis::Generator.new(config)

      # Should handle output directory creation errors gracefully
      expect_raises(Exception) do
        generator.build_with_analytics
      end

      FileUtils.rm_rf(test_dir)
    end
  end
end
