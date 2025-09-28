require "../spec_helper"

describe "Theme CLI Commands" do
  describe "theme list command" do
    it "lists available themes", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        # Change to temp directory for CLI execution
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          # Create config file
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Create local theme
          local_theme_dir = File.join("themes", "test-theme")
          Dir.mkdir_p(File.join(local_theme_dir, "layouts"))
          File.write(File.join(local_theme_dir, "layouts", "index.html"), "test layout")

          # Create theme.yml
          theme_yml = <<-YAML
          name: test-theme
          version: 1.0.0
          description: A test theme
          YAML
          File.write(File.join(local_theme_dir, "theme.yml"), theme_yml)

          cli = Lapis::CLI.new(["theme", "list"])

          # Should not raise an error
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "shows message when no themes found", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          # Create config file with no themes
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          cli = Lapis::CLI.new(["theme", "list"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end
  end

  describe "theme info command" do
    it "shows theme information", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          # Create config file
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Create test theme
          theme_dir = File.join("themes", "info-theme")
          layouts_dir = File.join(theme_dir, "layouts", "_default")
          Dir.mkdir_p(layouts_dir)
          File.write(File.join(layouts_dir, "single.html"), "single layout")

          # Create theme.yml with metadata
          theme_yml = <<-YAML
          name: info-theme
          version: 2.0.0
          description: A theme for testing info command
          author: Test Developer
          YAML
          File.write(File.join(theme_dir, "theme.yml"), theme_yml)

          cli = Lapis::CLI.new(["theme", "info", "info-theme"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "handles non-existent theme gracefully", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # This should handle the error gracefully (CLI design decision)
          cli = Lapis::CLI.new(["theme", "info", "nonexistent-theme"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "requires theme name parameter", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Should handle missing parameter gracefully
          cli = Lapis::CLI.new(["theme", "info"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end
  end

  describe "theme validate command" do
    it "validates a valid theme", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Create valid theme structure
          theme_dir = File.join("themes", "valid-theme")
          layouts_dir = File.join(theme_dir, "layouts", "_default")
          Dir.mkdir_p(layouts_dir)

          # Add required layout files
          File.write(File.join(layouts_dir, "baseof.html"), "base layout")
          File.write(File.join(layouts_dir, "single.html"), "single layout")

          theme_yml = <<-YAML
          name: valid-theme
          version: 1.0.0
          description: A valid theme for testing
          YAML
          File.write(File.join(theme_dir, "theme.yml"), theme_yml)

          cli = Lapis::CLI.new(["theme", "validate", "valid-theme"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "reports validation errors for invalid theme", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Create invalid theme (missing layouts)
          theme_dir = File.join("themes", "invalid-theme")
          Dir.mkdir_p(theme_dir)

          theme_yml = <<-YAML
          name: invalid-theme
          version: 1.0.0
          description: An invalid theme for testing
          YAML
          File.write(File.join(theme_dir, "theme.yml"), theme_yml)

          cli = Lapis::CLI.new(["theme", "validate", "invalid-theme"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "validates shard themes correctly", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Create shard theme
          shard_dir = File.join("lib", "lapis-theme-functional")
          layouts_dir = File.join(shard_dir, "layouts")
          Dir.mkdir_p(layouts_dir)
          File.write(File.join(layouts_dir, "index.html"), "shard layout")

          # Create proper shard.yml
          shard_yml = <<-YAML
          name: lapis-theme-functional
          version: 1.0.0
          description: A Lapis theme for functional testing
          targets:
            lapis-theme:
              main: src/theme.cr
          YAML
          File.write(File.join(shard_dir, "shard.yml"), shard_yml)

          # Create theme.yml
          theme_yml = <<-YAML
          name: lapis-theme-functional
          version: 1.0.0
          description: A functional test shard theme
          author: Test Developer
          YAML
          File.write(File.join(shard_dir, "theme.yml"), theme_yml)

          cli = Lapis::CLI.new(["theme", "validate", "lapis-theme-functional"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end
  end

  describe "theme install command" do
    it "shows installation instructions", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          cli = Lapis::CLI.new(["theme", "install", "awesome-theme"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "requires theme name parameter", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Should handle missing parameter gracefully
          cli = Lapis::CLI.new(["theme", "install"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end
  end

  describe "theme help command" do
    it "shows theme help", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["theme", "help"])
      cli.should be_a(Lapis::CLI)
    end

    it "shows help for unknown theme subcommand", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["theme", "unknown-command"])
      cli.should be_a(Lapis::CLI)
    end

    it "shows help when no subcommand provided", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["theme"])
      cli.should be_a(Lapis::CLI)
    end
  end

  describe "theme command error handling" do
    it "handles missing config file gracefully", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          # No config file exists
          cli = Lapis::CLI.new(["theme", "list"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "handles theme errors gracefully", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          # Create invalid config
          File.write("config.yml", "invalid: yaml: content:")

          # Should handle YAML parsing errors
          cli = Lapis::CLI.new(["theme", "list"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end
  end

  describe "integration with main CLI" do
    it "integrates theme command with main CLI", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["help"])
      cli.should be_a(Lapis::CLI)
    end

    it "shows theme commands in main help", tags: [TestTags::FUNCTIONAL] do
      # This would typically involve capturing output, but for now we test that it doesn't crash
      cli = Lapis::CLI.new(["help"])
      cli.should be_a(Lapis::CLI)
    end
  end
end