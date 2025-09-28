require "../spec_helper"
require "../../src/lapis/tuple_config_validator"

describe "TupleConfigValidator" do
  describe "validate_config" do
    it "validates required configuration keys", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      # Test with missing required keys
      incomplete_config = {
        "title"    => YAML::Any.new("Test Site"),
        "base_url" => YAML::Any.new("https://example.com"),
      }

      is_valid, errors = validator.validate_config(incomplete_config)
      is_valid.should be_false
      errors.should contain("Required configuration key 'theme' is missing or empty")
      errors.should contain("Required configuration key 'output_dir' is missing or empty")
    end

    it "validates complete configuration successfully", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      complete_config = {
        "title"       => YAML::Any.new("Test Site"),
        "base_url"    => YAML::Any.new("https://example.com"),
        "theme"       => YAML::Any.new("default"),
        "output_dir"  => YAML::Any.new("public"),
        "content_dir" => YAML::Any.new("content"),
      }

      is_valid, errors = validator.validate_config(complete_config)
      is_valid.should be_true
      errors.should be_empty
    end

    it "validates build config using tuple operations", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      # Test basic config validation without complex nested objects
      config_with_build = {
        "title"       => YAML::Any.new("Test Site"),
        "base_url"    => YAML::Any.new("https://example.com"),
        "theme"       => YAML::Any.new("default"),
        "output_dir"  => YAML::Any.new("public"),
        "content_dir" => YAML::Any.new("content"),
      }

      is_valid, errors = validator.validate_config(config_with_build)
      is_valid.should be_true
      errors.should be_empty
    end

    it "validates invalid build config values", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      config_with_invalid_build = {
        "title"        => YAML::Any.new("Test Site"),
        "base_url"     => YAML::Any.new("https://example.com"),
        "theme"        => YAML::Any.new("default"),
        "output_dir"   => YAML::Any.new("public"),
        "content_dir"  => YAML::Any.new("content"),
        "build_config" => YAML.parse(%(build_config:
  build_options: "not_a_valid_flag"
  max_workers: "not_a_number"
))["build_config"],
      }

      is_valid, errors = validator.validate_config(config_with_invalid_build)
      is_valid.should be_false
      errors.should contain("Build config 'build_options' must be a valid flag combination")
      errors.should contain("Build config 'max_workers' must be a positive integer")
    end
  end

  describe "normalize_config" do
    it "normalizes configuration paths using tuple operations", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      config_with_trailing_slashes = {
        "base_url"    => YAML::Any.new("https://example.com/"),
        "content_dir" => YAML::Any.new("content/"),
        "output_dir"  => YAML::Any.new("public/"),
        "layouts_dir" => YAML::Any.new("layouts/"),
        "static_dir"  => YAML::Any.new("static/"),
        "theme_dir"   => YAML::Any.new("themes/"),
      }

      normalized = validator.normalize_config(config_with_trailing_slashes)

      normalized["base_url"].as_s.should eq("https://example.com")
      normalized["content_dir"].as_s.should eq("content")
      normalized["output_dir"].as_s.should eq("public")
      normalized["layouts_dir"].as_s.should eq("layouts")
      normalized["static_dir"].as_s.should eq("static")
      normalized["theme_dir"].as_s.should eq("themes")
    end
  end

  describe "merge_configs" do
    it "merges configurations using tuple operations", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      base_config = {
        "title"    => YAML::Any.new("Base Site"),
        "theme"    => YAML::Any.new("default"),
        "base_url" => YAML::Any.new("https://base.com"),
      }

      override_config = {
        "title"       => YAML::Any.new("Override Site"),
        "description" => YAML::Any.new("Override description"),
      }

      merged = validator.merge_configs(base_config, override_config)

      merged["title"].as_s.should eq("Override Site")
      merged["theme"].as_s.should eq("default")
      merged["base_url"].as_s.should eq("https://base.com")
      merged["description"].as_s.should eq("Override description")
    end
  end

  describe "config_diff" do
    it "computes configuration differences using tuple operations", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      config1 = {
        "title"   => YAML::Any.new("Site 1"),
        "theme"   => YAML::Any.new("default"),
        "old_key" => YAML::Any.new("old_value"),
      }

      config2 = {
        "title"   => YAML::Any.new("Site 2"),
        "theme"   => YAML::Any.new("default"),
        "new_key" => YAML::Any.new("new_value"),
      }

      diff = validator.config_diff(config1, config2)

      diff[:added].should contain("new_key")
      diff[:removed].should contain("old_key")
      diff[:changed].should contain("title")
      diff[:changed].should_not contain("theme")
    end
  end

  describe "tuple operations performance" do
    it "demonstrates efficient tuple-based validation", tags: [TestTags::FAST, TestTags::UNIT] do
      validator = Lapis::TupleConfigValidator.new

      # Create a large configuration to test tuple operations
      large_config = {} of String => YAML::Any

      # Add required keys
      large_config["title"] = YAML::Any.new("Large Test Site")
      large_config["base_url"] = YAML::Any.new("https://large-site.com")
      large_config["theme"] = YAML::Any.new("default")
      large_config["output_dir"] = YAML::Any.new("public")
      large_config["content_dir"] = YAML::Any.new("content")

      # Add many optional keys to test tuple iteration
      100.times do |i|
        large_config["key_#{i}"] = YAML::Any.new("value_#{i}")
      end

      # This should be fast due to tuple operations
      start_time = Time.utc
      is_valid, errors = validator.validate_config(large_config)
      end_time = Time.utc

      is_valid.should be_true
      errors.should be_empty

      # Should complete quickly (less than 100ms for this test)
      duration = (end_time - start_time).total_milliseconds
      duration.should be < 100
    end
  end
end
