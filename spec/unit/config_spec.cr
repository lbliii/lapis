require "../spec_helper"

describe Lapis::Config do
  describe ".load" do
    it "loads configuration from file", tags: [TestTags::FAST, TestTags::UNIT] do
      config_content = <<-YAML
      title: Test Site
      port: 4000
      output_dir: test_output
      debug: true
      baseurl: https://example.com
      author: Test Author
      description: Test Description
      YAML

      with_temp_file(config_content) do |file_path|
        config = Lapis::Config.load(file_path)

        config.title.should eq("Test Site")
        config.port.should eq(4000)
        config.output_dir.should eq("test_output")
        config.debug.should be_true
        config.baseurl.should eq("https://example.com")
        config.author.should eq("Test Author")
        config.description.should eq("Test Description")
      end
    end

    it "uses defaults when config file is missing", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.load("nonexistent.yml")

      config.title.should eq("Lapis Site")
      config.port.should eq(3000)
      config.output_dir.should eq("public")
      config.debug.should be_false
    end

    it "handles invalid YAML gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_config = <<-YAML
      title: Test Site
      invalid: yaml: content: here
      YAML

      with_temp_file(invalid_config) do |file_path|
        expect_raises(Lapis::ConfigError) do
          Lapis::Config.load(file_path)
        end
      end
    end
  end

  describe "#validate" do
    it "validates configuration and sets defaults", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.output_dir = ""
      config.port = 0

      config.validate

      config.output_dir.should eq("public")
      config.port.should eq(3000)
    end

    it "validates build configuration", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.build_config.cache_dir = ""

      config.validate

      config.build_config.cache_dir.should eq(".lapis_cache")
    end
  end

  describe "logging configuration" do
    it "supports debug mode", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.debug = true
      config.debug.should be_true
    end

    it "supports log file configuration", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.log_file = "test.log"
      config.log_file.should eq("test.log")
    end

    it "supports log level configuration", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.log_level = "debug"
      config.log_level.should eq("debug")
    end
  end

  describe "build configuration" do
    it "has build configuration", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.build_config.should be_a(Lapis::BuildConfig)
    end

    it "supports incremental builds", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.build_config.incremental = true
      config.build_config.incremental.should be_true
    end

    it "supports parallel processing", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      config.build_config.parallel = true
      config.build_config.parallel.should be_true
    end
  end
end
