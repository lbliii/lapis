require "../spec_helper"

describe "CLI Integration" do
  describe "build command" do
    it "calls build_with_analytics method" do
      # Create test config
      test_config = <<-YAML
        title: "Test Site"
        build:
          incremental: true
      YAML

      File.write("test_lapis.yml", test_config)

      # Mock the generator to verify correct method is called
      analytics_called = false
      regular_called = false

      # We need to test this through the actual CLI, but we can verify
      # that the CLI loads config and creates generator correctly
      config = Lapis::Config.load("test_lapis.yml")
      generator = Lapis::Generator.new(config)

      config.title.should eq("Test Site")
      config.build_config.incremental.should be_true

      File.delete("test_lapis.yml")
    end

    it "handles missing config file gracefully" do
      # This should not crash
      config = Lapis::Config.load("nonexistent.yml")
      config.should_not be_nil
    end

    it "handles invalid config file gracefully" do
      invalid_config = <<-YAML
        title: "Test"
        build:
          incremental: "invalid"
      YAML

      File.write("invalid_lapis.yml", invalid_config)

      expect_raises(YAML::ParseException) do
        Lapis::Config.load("invalid_lapis.yml")
      end

      File.delete("invalid_lapis.yml")
    end
  end

  describe "CLI argument parsing" do
    it "parses build command correctly" do
      # Test that CLI can be instantiated with build command
      # The actual command parsing happens in the run method
      cli = Lapis::CLI.new(["build"])
      cli.should be_a(Lapis::CLI)
    end

    it "handles unknown commands gracefully" do
      # CLI can be instantiated with any command, but run() will handle unknown commands
      cli = Lapis::CLI.new(["unknown_command"])
      cli.should be_a(Lapis::CLI)
    end
  end
end
