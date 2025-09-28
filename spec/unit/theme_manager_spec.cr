require "../spec_helper"

describe Lapis::ThemeManager do
  describe "#initialize" do
    it "initializes with a theme name and project root", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        theme_manager.current_theme.should eq("default")
        theme_manager.theme_paths.should be_a(Array(String))
      end
    end

    it "builds theme paths in correct priority order", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create test theme structure
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        Dir.mkdir_p(File.join(theme_dir, "layouts"))

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        theme_manager.theme_paths.should_not be_empty
        theme_manager.theme_paths.first.includes?("test-theme").should be_true
      end
    end

    it "uses custom theme directory when provided", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create custom theme directory outside of standard locations
        custom_theme_dir = File.join(temp_dir, "custom", "my-theme")
        Dir.mkdir_p(File.join(custom_theme_dir, "layouts"))
        File.write(File.join(custom_theme_dir, "layouts", "baseof.html"), "custom theme")

        # Initialize with custom theme directory
        theme_manager = Lapis::ThemeManager.new("my-theme", temp_dir, "custom/my-theme")

        theme_manager.theme_paths.should_not be_empty
        theme_manager.theme_paths.first.should eq(File.expand_path("custom/my-theme", temp_dir))
        
        # Should be able to resolve files from custom theme directory
        resolved_path = theme_manager.resolve_file("baseof.html", "layout")
        resolved_path.should_not be_nil
        File.read(resolved_path.not_nil!).should eq("custom theme")
      end
    end

    it "prioritizes custom theme directory over standard locations", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create standard theme location
        standard_theme_dir = File.join(temp_dir, "themes", "test-theme")
        Dir.mkdir_p(File.join(standard_theme_dir, "layouts"))
        File.write(File.join(standard_theme_dir, "layouts", "baseof.html"), "standard theme")

        # Create custom theme directory with same theme name
        custom_theme_dir = File.join(temp_dir, "custom", "test-theme")
        Dir.mkdir_p(File.join(custom_theme_dir, "layouts"))
        File.write(File.join(custom_theme_dir, "layouts", "baseof.html"), "custom theme")

        # Initialize with custom theme directory
        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir, "custom/test-theme")

        # Custom theme should be first in paths
        theme_manager.theme_paths.first.should eq(File.expand_path("custom/test-theme", temp_dir))
        
        # Should resolve to custom theme file
        resolved_path = theme_manager.resolve_file("baseof.html", "layout")
        resolved_path.should_not be_nil
        File.read(resolved_path.not_nil!).should eq("custom theme")
      end
    end

    it "handles relative custom theme directory paths correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create theme in parent directory
        parent_theme_dir = File.join(File.dirname(temp_dir), "themes", "parent-theme")
        Dir.mkdir_p(File.join(parent_theme_dir, "layouts"))
        File.write(File.join(parent_theme_dir, "layouts", "baseof.html"), "parent theme")

        # Initialize with relative path to parent directory
        theme_manager = Lapis::ThemeManager.new("parent-theme", temp_dir, "../themes/parent-theme")

        theme_manager.theme_paths.should_not be_empty
        theme_manager.theme_paths.first.should eq(File.expand_path("../themes/parent-theme", temp_dir))
        
        # Should be able to resolve files
        resolved_path = theme_manager.resolve_file("baseof.html", "layout")
        resolved_path.should_not be_nil
        File.read(resolved_path.not_nil!).should eq("parent theme")
      end
    end

    it "ignores custom theme directory if it doesn't exist", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create standard theme location
        standard_theme_dir = File.join(temp_dir, "themes", "test-theme")
        Dir.mkdir_p(File.join(standard_theme_dir, "layouts"))

        # Initialize with non-existent custom theme directory
        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir, "../nonexistent/theme")

        # Should fall back to standard theme location
        theme_manager.theme_paths.should_not be_empty
        theme_manager.theme_paths.first.should eq(standard_theme_dir)
      end
    end
  end

  describe "#resolve_file" do
    it "resolves layout files with proper priority", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create user layout override
        user_layouts_dir = File.join(temp_dir, "layouts")
        Dir.mkdir_p(user_layouts_dir)
        File.write(File.join(user_layouts_dir, "test.html"), "user layout")

        # Create theme layout
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        theme_layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(theme_layouts_dir)
        File.write(File.join(theme_layouts_dir, "test.html"), "theme layout")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        # Should resolve to user layout (higher priority)
        resolved_path = theme_manager.resolve_file("test.html", "layout")
        resolved_path.should_not be_nil
        resolved_path.not_nil!.includes?("layouts/test.html").should be_true
        File.read(resolved_path.not_nil!).should eq("user layout")
      end
    end

    it "falls back to theme layout when user layout doesn't exist", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create only theme layout
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        theme_layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(theme_layouts_dir)
        File.write(File.join(theme_layouts_dir, "test.html"), "theme layout")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        resolved_path = theme_manager.resolve_file("test.html", "layout")
        resolved_path.should_not be_nil
        File.read(resolved_path.not_nil!).should eq("theme layout")
      end
    end

    it "returns nil when file doesn't exist anywhere", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("nonexistent-theme", temp_dir)

        resolved_path = theme_manager.resolve_file("nonexistent.html", "layout")
        resolved_path.should be_nil
      end
    end

    it "resolves partial files correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create theme partial
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        partials_dir = File.join(theme_dir, "layouts", "partials")
        Dir.mkdir_p(partials_dir)
        File.write(File.join(partials_dir, "header.html"), "partial content")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        resolved_path = theme_manager.resolve_file("header.html", "partial")
        resolved_path.should_not be_nil
        File.read(resolved_path.not_nil!).should eq("partial content")
      end
    end

    it "resolves asset files correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create theme asset
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        static_dir = File.join(theme_dir, "static")
        Dir.mkdir_p(static_dir)
        File.write(File.join(static_dir, "style.css"), "css content")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        resolved_path = theme_manager.resolve_file("style.css", "asset")
        resolved_path.should_not be_nil
        File.read(resolved_path.not_nil!).should eq("css content")
      end
    end
  end

  describe "#collect_all_assets" do
    it "collects assets from all theme sources", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create theme assets
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        theme_static = File.join(theme_dir, "static")
        Dir.mkdir_p(theme_static)
        File.write(File.join(theme_static, "theme.css"), "theme css")

        # Create user assets (should override)
        user_static = File.join(temp_dir, "static")
        Dir.mkdir_p(user_static)
        File.write(File.join(user_static, "user.css"), "user css")
        File.write(File.join(user_static, "theme.css"), "user override css")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        assets = theme_manager.collect_all_assets
        assets.has_key?("user.css").should be_true
        assets.has_key?("theme.css").should be_true

        # User assets should override theme assets
        File.read(assets["theme.css"]).should eq("user override css")
        File.read(assets["user.css"]).should eq("user css")
      end
    end

    it "handles nested asset directories", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        css_dir = File.join(theme_dir, "static", "css")
        js_dir = File.join(theme_dir, "static", "js")
        Dir.mkdir_p(css_dir)
        Dir.mkdir_p(js_dir)

        File.write(File.join(css_dir, "style.css"), "css")
        File.write(File.join(js_dir, "script.js"), "js")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        assets = theme_manager.collect_all_assets
        assets.has_key?("css/style.css").should be_true
        assets.has_key?("js/script.js").should be_true
      end
    end
  end

  describe "#theme_available?" do
    it "returns true when theme has required layout files", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "default.html"), "layout content")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        theme_manager.theme_available?.should be_true
      end
    end

    it "returns false when theme has no layout files", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("nonexistent-theme", temp_dir)

        theme_manager.theme_available?.should be_false
      end
    end
  end

  describe "#validate_theme" do
    it "validates a properly structured theme", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        layouts_dir = File.join(theme_dir, "layouts")
        default_dir = File.join(layouts_dir, "_default")
        Dir.mkdir_p(default_dir)

        File.write(File.join(default_dir, "baseof.html"), "base layout")
        File.write(File.join(default_dir, "single.html"), "single layout")
        File.write(File.join(theme_dir, "theme.yml"), "name: test-theme")

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        validation = theme_manager.validate_theme(theme_dir)
        validation["valid"].should be_true
        validation["has_layouts"].should be_true
        validation["has_baseof"].should be_true
        validation["has_default_layout"].should be_true
        validation["has_theme_config"].should be_true
      end
    end

    it "reports missing layouts directory", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        Dir.mkdir_p(theme_dir)

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        validation = theme_manager.validate_theme(theme_dir)
        validation["valid"].should be_false
        validation["has_layouts"].should be_false
        validation["error"].as(String).includes?("Missing layouts directory").should be_true
      end
    end

    it "reports missing theme directory", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        validation = theme_manager.validate_theme("/nonexistent/path")
        validation["valid"].should be_false
        validation["error"].as(String).includes?("Theme directory does not exist").should be_true
      end
    end
  end

  describe "#validate_shard_theme" do
    it "validates a properly structured shard theme", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        shard_dir = File.join(temp_dir, "lib", "lapis-theme-test")
        layouts_dir = File.join(shard_dir, "layouts")
        default_dir = File.join(layouts_dir, "_default")
        Dir.mkdir_p(default_dir)

        File.write(File.join(default_dir, "single.html"), "layout")

        shard_yml = <<-YAML
        name: lapis-theme-test
        version: 1.0.0
        description: A Lapis theme for testing
        targets:
          lapis-theme:
            main: src/theme.cr
        YAML
        File.write(File.join(shard_dir, "shard.yml"), shard_yml)

        theme_manager = Lapis::ThemeManager.new("lapis-theme-test", temp_dir)

        validation = theme_manager.validate_shard_theme(shard_dir)
        validation["valid"].should be_true
      end
    end

    it "reports missing shard.yml", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        shard_dir = File.join(temp_dir, "lib", "test-theme")
        layouts_dir = File.join(shard_dir, "layouts")
        Dir.mkdir_p(layouts_dir)

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        validation = theme_manager.validate_shard_theme(shard_dir)
        validation["valid"].should be_false
        validation["error"].as(String).includes?("Missing shard.yml file").should be_true
      end
    end

    it "reports invalid shard.yml structure", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        shard_dir = File.join(temp_dir, "lib", "test-theme")
        layouts_dir = File.join(shard_dir, "layouts")
        Dir.mkdir_p(layouts_dir)

        # Missing required fields
        shard_yml = "description: Missing name and version"
        File.write(File.join(shard_dir, "shard.yml"), shard_yml)

        theme_manager = Lapis::ThemeManager.new("test-theme", temp_dir)

        validation = theme_manager.validate_shard_theme(shard_dir)
        validation["valid"].should be_false
        validation["error"].as(String).includes?("shard.yml missing name field").should be_true
      end
    end

    it "reports when shard is not identified as Lapis theme", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        shard_dir = File.join(temp_dir, "lib", "regular-shard")
        layouts_dir = File.join(shard_dir, "layouts")
        Dir.mkdir_p(layouts_dir)

        shard_yml = <<-YAML
        name: regular-shard
        version: 1.0.0
        description: Just a regular Crystal shard
        YAML
        File.write(File.join(shard_dir, "shard.yml"), shard_yml)

        theme_manager = Lapis::ThemeManager.new("regular-shard", temp_dir)

        validation = theme_manager.validate_shard_theme(shard_dir)
        validation["valid"].should be_false
        validation["error"].as(String).includes?("Shard not identified as a Lapis theme").should be_true
      end
    end
  end

  describe "#detect_shard_themes" do
    it "detects valid Lapis theme shards", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create a valid theme shard
        shard_dir = File.join(temp_dir, "lib", "lapis-theme-blog")
        layouts_dir = File.join(shard_dir, "layouts")
        Dir.mkdir_p(layouts_dir)
        File.write(File.join(layouts_dir, "index.html"), "layout")

        shard_yml = <<-YAML
        name: lapis-theme-blog
        version: 1.0.0
        description: A Lapis theme for blogging
        targets:
          lapis-theme:
            main: src/theme.cr
        YAML
        File.write(File.join(shard_dir, "shard.yml"), shard_yml)

        # Create theme.yml for theme metadata
        theme_yml = <<-YAML
        name: lapis-theme-blog
        version: 1.0.0
        description: A blog theme for Lapis
        author: Test Author
        YAML
        File.write(File.join(shard_dir, "theme.yml"), theme_yml)

        # Create a non-theme shard
        other_shard_dir = File.join(temp_dir, "lib", "other-shard")
        Dir.mkdir_p(other_shard_dir)
        File.write(File.join(other_shard_dir, "shard.yml"), "name: other-shard\nversion: 1.0.0")

        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        shard_themes = theme_manager.detect_shard_themes
        shard_themes.size.should eq(1)
        shard_themes.first.name.should eq("lapis-theme-blog")
      end
    end

    it "returns empty array when no theme shards exist", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        shard_themes = theme_manager.detect_shard_themes
        shard_themes.should be_empty
      end
    end
  end

  describe "#list_available_themes" do
    it "lists themes from all sources with correct priorities", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create local theme
        local_theme_dir = File.join(temp_dir, "themes", "local-theme")
        Dir.mkdir_p(File.join(local_theme_dir, "layouts"))

        # Create shard theme
        shard_dir = File.join(temp_dir, "lib", "lapis-theme-shard")
        Dir.mkdir_p(File.join(shard_dir, "layouts"))
        shard_yml = <<-YAML
        name: lapis-theme-shard
        version: 1.0.0
        description: A Lapis theme for testing
        targets:
          lapis-theme:
            main: src/theme.cr
        YAML
        File.write(File.join(shard_dir, "shard.yml"), shard_yml)

        # Create theme.yml for theme metadata
        theme_yml = <<-YAML
        name: lapis-theme-shard
        version: 1.0.0
        description: A shard theme for Lapis
        author: Test Author
        YAML
        File.write(File.join(shard_dir, "theme.yml"), theme_yml)

        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        themes = theme_manager.list_available_themes
        themes.has_key?("local-theme").should be_true
        themes.has_key?("lapis-theme-shard").should be_true
        themes["local-theme"].should eq("local")
        themes["lapis-theme-shard"].should eq("shard")
      end
    end
  end

  describe "#theme_exists?" do
    it "returns true for existing themes", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_dir = File.join(temp_dir, "themes", "test-theme")
        Dir.mkdir_p(File.join(theme_dir, "layouts"))

        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        theme_manager.theme_exists?("test-theme").should be_true
      end
    end

    it "returns false for non-existing themes", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        theme_manager.theme_exists?("nonexistent-theme").should be_false
      end
    end
  end

  describe "#theme_source" do
    it "returns 'embedded' for default theme", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        theme_manager.theme_source("default").should eq("embedded")
      end
    end

    it "returns correct source type for themes", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        # Create local theme
        local_theme_dir = File.join(temp_dir, "themes", "local-theme")
        Dir.mkdir_p(File.join(local_theme_dir, "layouts"))

        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        theme_manager.theme_source("local-theme").should eq("local")
      end
    end

    it "returns nil for non-existing themes", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        theme_manager = Lapis::ThemeManager.new("default", temp_dir)

        theme_manager.theme_source("nonexistent").should be_nil
      end
    end
  end
end