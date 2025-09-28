require "../spec_helper"

describe "Configuration Loading" do
  describe "BuildConfig" do
    it "loads incremental setting from config file" do
      config_yaml = <<-YAML
        build:
          incremental: true
          parallel: false
          cache_dir: ".test-cache"
          max_workers: 2
          clean_build: true
      YAML

      config = Config.from_yaml(config_yaml)

      config.build_config.incremental.should be_true
      config.build_config.parallel.should be_false
      config.build_config.cache_dir.should eq(".test-cache")
      config.build_config.max_workers.should eq(2)
      config.build_config.clean_build.should be_true
    end

    it "uses default values when config is missing" do
      config_yaml = <<-YAML
        title: "Test Site"
      YAML

      config = Config.from_yaml(config_yaml)

      config.build_config.incremental.should be_true          # default
      config.build_config.parallel.should be_true             # default
      config.build_config.cache_dir.should eq(".lapis-cache") # default
      config.build_config.max_workers.should eq(4)            # default
      config.build_config.clean_build.should be_false         # default
    end

    it "handles invalid config gracefully" do
      invalid_yaml = <<-YAML
        build:
          incremental: "not_a_boolean"
          max_workers: "not_a_number"
      YAML

      expect_raises(YAML::ParseException) do
        Config.from_yaml(invalid_yaml)
      end
    end

    it "validates max_workers returns Int32" do
      config = Config.new
      config.build_config.max_workers = 8

      result = config.build_config.max_workers
      result.should be_a(Int32)
      result.should eq(8)
    end
  end

  describe "Config file loading" do
    it "loads config from lapis.yml file" do
      # Create test config file
      test_config = <<-YAML
        title: "Test Site"
        build:
          incremental: true
          parallel: true
        theme: "default"
      YAML

      File.write("test_lapis.yml", test_config)

      config = Config.load("test_lapis.yml")

      config.title.should eq("Test Site")
      config.build_config.incremental.should be_true
      config.build_config.parallel.should be_true
      config.theme.should eq("default")

      File.delete("test_lapis.yml")
    end

    it "falls back to default config when file doesn't exist" do
      config = Config.load("nonexistent.yml")

      config.title.should eq("My Site")              # default
      config.build_config.incremental.should be_true # default
    end
  end
end
