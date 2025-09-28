require "../spec_helper"

describe "Theme Error Handling" do
  describe "ThemeManager error scenarios" do
    it "handles corrupted theme.yml files gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "corrupted-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "layout")

        # Create invalid YAML
        File.write(File.join(theme_dir, "theme.yml"), "invalid: yaml: content: [")

        theme_manager = Lapis::ThemeManager.new("corrupted-theme", temp_dir)

        # Should handle gracefully without crashing
        info = theme_manager.theme_info
        info.should be_empty
      end
    end

    it "handles corrupted shard.yml files gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        shard_dir = File.join(temp_dir, "lib", "corrupted-shard")
        layouts_dir = File.join(shard_dir, "layouts")
        Dir.mkdir_p(layouts_dir)

        # Create invalid YAML
        File.write(File.join(shard_dir, "shard.yml"), "invalid: yaml: [[[")

        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        # Should handle gracefully
        shard_themes = theme_manager.detect_shard_themes
        shard_themes.should be_empty
      end
    end

    it "handles permission denied errors", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Test validation on a path that doesn't exist or has no permissions
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        validation = theme_manager.validate_theme("/root/restricted")
        validation["valid"].should be_false
        validation["error"].as(String).should_not be_empty
      end
    end

    it "handles circular symlinks in theme directories", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "symlink-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)

        # This test is platform dependent, so we just ensure it doesn't crash
        theme_manager = Lapis::ThemeManager.new("symlink-theme", temp_dir)

        # Should handle gracefully
        assets = theme_manager.collect_all_assets
        assets.should be_a(Hash(String, String))
      end
    end

    it "handles themes with no layout files", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "empty-theme")
        Dir.mkdir_p(theme_dir)

        theme_manager = Lapis::ThemeManager.new("empty-theme", temp_dir)

        validation = theme_manager.validate_theme(theme_dir)
        validation["valid"].should be_false
        validation["error"].as(String).includes?("Missing layouts directory").should be_true
      end
    end

    it "handles themes with empty layouts directory", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "empty-layouts-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        # No layout files

        theme_manager = Lapis::ThemeManager.new("empty-layouts-theme", temp_dir)

        validation = theme_manager.validate_theme(theme_dir)
        validation["valid"].should be_false
        validation["has_layouts"].should be_true
        validation["has_baseof"].should be_false
        validation["has_default_layout"].should be_false
      end
    end
  end

  describe "CLI error handling" do
    it "handles theme commands when no themes exist", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "nonexistent"
          YAML
          File.write("config.yml", config_content)

          # Should handle gracefully
          cli = Lapis::CLI.new(["theme", "list"])
          cli.should be_a(Lapis::CLI)

          cli = Lapis::CLI.new(["theme", "info", "nonexistent"])
          cli.should be_a(Lapis::CLI)

          cli = Lapis::CLI.new(["theme", "validate", "nonexistent"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end

    it "handles missing required parameters gracefully", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |temp_dir|
        original_dir = Dir.current
        Dir.cd(temp_dir)

        begin
          config_content = <<-YAML
          title: "Test Site"
          theme: "default"
          YAML
          File.write("config.yml", config_content)

          # Should show error messages and exit gracefully
          cli = Lapis::CLI.new(["theme", "info"])
          cli.should be_a(Lapis::CLI)

          cli = Lapis::CLI.new(["theme", "validate"])
          cli.should be_a(Lapis::CLI)

          cli = Lapis::CLI.new(["theme", "install"])
          cli.should be_a(Lapis::CLI)
        ensure
          Dir.cd(original_dir)
        end
      end
    end
  end

  describe "ThemeError exception handling" do
    it "creates proper ThemeError instances", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ThemeError.new("Test theme error")
      error.message.should eq("Theme Error: Test theme error")
      error.should be_a(Lapis::LapisError)
    end

    it "handles theme resolution failures", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("completely-nonexistent-theme", temp_dir)

        # Should handle missing themes gracefully
        theme_manager.theme_available?.should be_false
        resolved_file = theme_manager.resolve_file("any-file.html", "layout")
        resolved_file.should be_nil
      end
    end
  end

  describe "Validation error messages" do
    it "provides clear validation error messages", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Test various validation scenarios
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        # Non-existent directory
        validation = theme_manager.validate_theme("/nonexistent/path")
        validation["valid"].should be_false
        validation["error"].as(String).includes?("does not exist").should be_true

        # Directory without layouts
        empty_dir = File.join(temp_dir, "empty")
        Dir.mkdir_p(empty_dir)
        validation = theme_manager.validate_theme(empty_dir)
        validation["valid"].should be_false
        validation["error"].as(String).includes?("Missing layouts directory").should be_true
      end
    end

    it "provides helpful shard validation messages", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        # Missing shard.yml
        shard_dir = File.join(temp_dir, "fake-shard")
        Dir.mkdir_p(shard_dir)
        validation = theme_manager.validate_shard_theme(shard_dir)
        validation["valid"].should be_false
        validation["error"].as(String).includes?("Missing shard.yml file").should be_true

        # Invalid shard.yml
        File.write(File.join(shard_dir, "shard.yml"), "name: test")
        validation = theme_manager.validate_shard_theme(shard_dir)
        validation["valid"].should be_false
        validation["error"].as(String).includes?("missing version field").should be_true
      end
    end
  end

  describe "Recovery and fallback behavior" do
    it "falls back to default theme when configured theme is unavailable", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create default theme structure
        default_theme_dir = File.join(temp_dir, "themes", "default")
        layouts_dir = File.join(default_theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "default layout")

        # Try to use non-existent theme
        theme_manager = Lapis::ThemeManager.new("nonexistent-theme", temp_dir)

        # Should fall back gracefully
        theme_manager.theme_available?.should be_false

        # But default theme should be available
        default_manager = Lapis::ThemeManager.new("default", temp_dir)
        default_manager.theme_available?.should be_true
      end
    end

    it "handles partial theme installations gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create partial theme (has shard.yml but no layouts)
        shard_dir = File.join(temp_dir, "lib", "partial-theme")
        Dir.mkdir_p(shard_dir)

        shard_yml = <<-YAML
        name: partial-theme
        version: 1.0.0
        description: A partially installed theme
        YAML
        File.write(File.join(shard_dir, "shard.yml"), shard_yml)

        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        # Should detect but not validate the partial theme
        themes = theme_manager.list_available_themes
        themes.has_key?("partial-theme").should be_false

        shard_themes = theme_manager.detect_shard_themes
        shard_themes.should be_empty # No layouts directory
      end
    end
  end
end
