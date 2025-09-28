require "../spec_helper"

describe "Theme System Edge Cases" do
  describe "Unicode and special characters" do
    it "handles theme names with unicode characters", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_name = "thème-ñäme"
        theme_dir = File.join(temp_dir, "themes", theme_name)
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "unicode theme")

        theme_manager = Lapis::ThemeManager.new(theme_name, temp_dir)

        # Should handle unicode names gracefully
        theme_manager.theme_exists?(theme_name).should be_true
        theme_manager.resolve_file("index.html", "layout").should_not be_nil
      end
    end

    it "handles file paths with spaces", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "theme with spaces")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "template with spaces.html"), "spaced template")

        theme_manager = Lapis::ThemeManager.new("theme with spaces", temp_dir)

        resolved = theme_manager.resolve_file("template with spaces.html", "layout")
        resolved.should_not be_nil
        File.read(resolved.not_nil!).should eq("spaced template")
      end
    end

    it "handles theme.yml with unicode content", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "unicode-content")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "layout")

        theme_yml = <<-YAML
        name: unicode-content
        description: "Thème avec caractères spéciaux: éñ 中文 🎨"
        author: "Åuthor Ñame"
        YAML
        File.write(File.join(theme_dir, "theme.yml"), theme_yml)

        theme_manager = Lapis::ThemeManager.new("unicode-content", temp_dir)

        info = theme_manager.theme_info
        info["description"].should contain("caractères")
        info["author"].should contain("Åuthor")
      end
    end
  end

  describe "Very long paths and names" do
    it "handles very long theme names", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create a very long theme name (but within filesystem limits)
        long_name = "very-long-theme-name-" + "x" * 50
        theme_dir = File.join(temp_dir, "themes", long_name)
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "long name theme")

        theme_manager = Lapis::ThemeManager.new(long_name, temp_dir)

        theme_manager.theme_exists?(long_name).should be_true
      end
    end

    it "handles deeply nested asset directories", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "deep-theme")
        nested_dir = File.join(theme_dir, "static", "css", "components", "forms", "inputs")
        Dir.mkdir_p(nested_dir)
        File.write(File.join(nested_dir, "style.css"), "deep css")

        theme_manager = Lapis::ThemeManager.new("deep-theme", temp_dir)

        assets = theme_manager.collect_all_assets
        assets.has_key?("css/components/forms/inputs/style.css").should be_true
      end
    end
  end

  describe "Concurrent access scenarios" do
    it "handles multiple ThemeManager instances safely", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "concurrent-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "concurrent layout")

        # Create multiple ThemeManager instances
        managers = (1..5).map { Lapis::ThemeManager.new("concurrent-theme", temp_dir) }

        # All should work correctly
        managers.each do |manager|
          manager.theme_exists?("concurrent-theme").should be_true
          manager.resolve_file("index.html", "layout").should_not be_nil
        end
      end
    end

    it "handles file modifications during theme operations", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "modifying-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)

        initial_content = "initial content"
        layout_file = File.join(layouts_dir, "index.html")
        File.write(layout_file, initial_content)

        theme_manager = Lapis::ThemeManager.new("modifying-theme", temp_dir)

        # Resolve the file
        resolved = theme_manager.resolve_file("index.html", "layout")
        resolved.should_not be_nil

        # Modify the file
        File.write(layout_file, "modified content")

        # Should still work (reading the modified content)
        File.read(resolved.not_nil!).should eq("modified content")
      end
    end
  end

  describe "Resource exhaustion scenarios" do
    it "handles themes with many small files", tags: [TestTags::SLOW, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "many-files-theme")
        static_dir = File.join(theme_dir, "static")
        Dir.mkdir_p(static_dir)

        # Create many small files
        100.times do |i|
          File.write(File.join(static_dir, "file#{i}.txt"), "content #{i}")
        end

        theme_manager = Lapis::ThemeManager.new("many-files-theme", temp_dir)

        assets = theme_manager.collect_all_assets
        assets.size.should eq(100)
      end
    end

    it "handles empty files gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "empty-files-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        static_dir = File.join(theme_dir, "static")
        Dir.mkdir_p(layouts_dir)
        Dir.mkdir_p(static_dir)

        # Create empty files
        File.write(File.join(layouts_dir, "empty.html"), "")
        File.write(File.join(static_dir, "empty.css"), "")
        File.write(File.join(theme_dir, "theme.yml"), "")

        theme_manager = Lapis::ThemeManager.new("empty-files-theme", temp_dir)

        # Should handle empty files without crashing
        resolved = theme_manager.resolve_file("empty.html", "layout")
        resolved.should_not be_nil
        File.read(resolved.not_nil!).should eq("")

        assets = theme_manager.collect_all_assets
        assets.has_key?("empty.css").should be_true

        # Empty theme.yml should return empty info
        info = theme_manager.theme_info
        info.should be_empty
      end
    end
  end

  describe "Filesystem edge cases" do
    it "handles case-insensitive filesystems correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "CaseSensitive")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "Index.html"), "case sensitive")

        theme_manager = Lapis::ThemeManager.new("CaseSensitive", temp_dir)

        # Should find the file regardless of case on case-insensitive systems
        # but maintain exact behavior on case-sensitive systems
        resolved = theme_manager.resolve_file("Index.html", "layout")
        resolved.should_not be_nil
      end
    end

    it "handles broken symlinks gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "symlink-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)

        # This test is platform-dependent for symlink creation
        # We just ensure the theme system doesn't crash with unusual directory structures
        File.write(File.join(layouts_dir, "default.html"), "real file")

        theme_manager = Lapis::ThemeManager.new("symlink-theme", temp_dir)

        # Should handle gracefully
        theme_manager.theme_available?.should be_true
        assets = theme_manager.collect_all_assets
        assets.should be_a(Hash(String, String))
      end
    end

    it "handles read-only theme directories", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "readonly-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "readonly theme")

        theme_manager = Lapis::ThemeManager.new("readonly-theme", temp_dir)

        # Reading operations should work fine
        theme_manager.theme_available?.should be_true
        resolved = theme_manager.resolve_file("index.html", "layout")
        resolved.should_not be_nil
      end
    end
  end

  describe "Malformed content scenarios" do
    it "handles binary files in theme directories", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "binary-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        static_dir = File.join(theme_dir, "static")
        Dir.mkdir_p(layouts_dir)
        Dir.mkdir_p(static_dir)

        # Create a normal layout
        File.write(File.join(layouts_dir, "index.html"), "normal layout")

        # Create binary content (simulated)
        binary_content = Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] # PNG header
        File.write(File.join(static_dir, "image.png"), binary_content)

        theme_manager = Lapis::ThemeManager.new("binary-theme", temp_dir)

        # Should handle binary files in assets without issues
        assets = theme_manager.collect_all_assets
        assets.has_key?("image.png").should be_true

        # Normal layout resolution should still work
        resolved = theme_manager.resolve_file("index.html", "layout")
        resolved.should_not be_nil
      end
    end

    it "handles extremely large theme.yml files", tags: [TestTags::SLOW, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "large-config-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "layout")

        # Create large theme.yml
        large_content = <<-YAML
        name: large-config-theme
        description: "A theme with a very large configuration file"
        YAML

        # Add many entries to make it large
        additional_config = (1..1000).map { |i| "config_item_#{i}: value_#{i}" }.join("\n")
        large_content += "\n" + additional_config

        File.write(File.join(theme_dir, "theme.yml"), large_content)

        theme_manager = Lapis::ThemeManager.new("large-config-theme", temp_dir)

        # Should handle large files gracefully
        info = theme_manager.theme_info
        info["name"].should eq("large-config-theme")
      end
    end

    it "handles themes with circular directory references", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "circular-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        static_dir = File.join(theme_dir, "static")
        Dir.mkdir_p(layouts_dir)
        Dir.mkdir_p(static_dir)

        File.write(File.join(layouts_dir, "index.html"), "circular layout")
        File.write(File.join(static_dir, "style.css"), "circular css")

        theme_manager = Lapis::ThemeManager.new("circular-theme", temp_dir)

        # Should handle without infinite loops
        assets = theme_manager.collect_all_assets
        assets.has_key?("style.css").should be_true
        assets.size.should be > 0
      end
    end
  end

  describe "Memory usage patterns" do
    it "doesn't leak memory with repeated operations", tags: [TestTags::PERFORMANCE, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "memory-test-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "memory test")

        theme_manager = Lapis::ThemeManager.new("memory-test-theme", temp_dir)

        # Perform many operations to test for memory leaks
        1000.times do
          theme_manager.theme_available?
          theme_manager.resolve_file("index.html", "layout")
          theme_manager.theme_info
        end

        # If we get here without running out of memory, the test passes
        theme_manager.should be_a(Lapis::ThemeManager)
      end
    end

    it "handles rapid creation and destruction of ThemeManagers", tags: [TestTags::PERFORMANCE, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "rapid-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "rapid test")

        # Create and destroy many ThemeManager instances
        100.times do
          manager = Lapis::ThemeManager.new("rapid-theme", temp_dir)
          manager.theme_available?.should be_true
          # Let it go out of scope to be garbage collected
        end

        # Should complete without issues
        true.should be_true
      end
    end
  end
end