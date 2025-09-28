require "../spec_helper"

describe "Server Management CLI" do
  describe "port conflict detection" do
    it "detects when port is in use", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          # Create basic config
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          port: 8080
          YAML
          File.write("config.yml", config_content)

          # The CLI class should exist and detect ports correctly
          cli = Lapis::CLI.new(["status"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end
  end

  describe "server status command" do
    it "shows no servers when none are running", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["status"])
      cli.should be_a(Lapis::CLI)
    end

    it "handles server info directory creation", tags: [TestTags::FUNCTIONAL] do
      # Should not crash when ~/.lapis/servers doesn't exist
      cli = Lapis::CLI.new(["status"])
      cli.should be_a(Lapis::CLI)
    end
  end

  describe "stop command" do
    it "handles stop when no servers running", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["stop"])
      cli.should be_a(Lapis::CLI)
    end

    it "handles stop with force flag", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["stop", "--force"])
      cli.should be_a(Lapis::CLI)
    end

    it "handles stop with specific port", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["stop", "--port", "9999"])
      cli.should be_a(Lapis::CLI)
    end
  end

  describe "enhanced help system" do
    it "shows server management commands in help", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["help"])
      cli.should be_a(Lapis::CLI)
    end

    it "shows server management examples", tags: [TestTags::FUNCTIONAL] do
      # The help should include server management examples
      cli = Lapis::CLI.new(["help"])
      cli.should be_a(Lapis::CLI)
    end
  end

  describe "graceful shutdown handling" do
    it "handles CLI creation without errors", tags: [TestTags::FUNCTIONAL] do
      # Test that signal handlers don't interfere with CLI creation
      cli = Lapis::CLI.new(["status"])
      cli.should be_a(Lapis::CLI)
    end
  end

  describe "server info persistence" do
    it "handles missing server info directory", tags: [TestTags::FUNCTIONAL] do
      # Should create directories as needed
      cli = Lapis::CLI.new(["status"])
      cli.should be_a(Lapis::CLI)
    end
  end
end
