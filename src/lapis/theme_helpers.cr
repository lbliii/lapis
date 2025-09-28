module Lapis
  # Theme helper methods for CSS and asset management
  module ThemeHelpers
    # Build CSS includes with proper cascade priority:
    # 1. Theme base CSS (themes/default/static/css/style.css)
    # 2. Site custom CSS (static/css/custom.css)
    # 3. Page-specific CSS (static/css/page-name.css)
    def build_css_includes(page_name : String? = nil) : Array(String)
      css_files = [] of String

      # 1. Theme base CSS - always loaded first
      theme_css = theme_css_path("style.css")
      if File.exists?(theme_css)
        css_files << %(<link rel="stylesheet" href="/assets/css/style.css">)
      end

      # 2. Site custom CSS - overrides theme
      site_custom = site_css_path("custom.css")
      if File.exists?(site_custom)
        css_files << %(<link rel="stylesheet" href="/assets/css/custom.css">)
      end

      # 3. Page-specific CSS - highest priority
      if page_name
        page_css = site_css_path("#{page_name}.css")
        if File.exists?(page_css)
          css_files << %(<link rel="stylesheet" href="/assets/css/#{page_name}.css">)
        end
      end

      css_files
    end

    # Get theme CSS file path
    def theme_css_path(filename : String) : String
      File.join(@config.theme_dir, "static", "css", filename)
    end

    # Get site CSS file path
    def site_css_path(filename : String) : String
      File.join(@config.static_dir, "css", filename)
    end

    # Check if a CSS file exists in theme
    def theme_css_exists?(filename : String) : Bool
      File.exists?(theme_css_path(filename))
    end

    # Check if a CSS file exists in site
    def site_css_exists?(filename : String) : Bool
      File.exists?(site_css_path(filename))
    end

    # Get all available CSS files for debugging
    def list_available_css : Hash(String, Array(String))
      {
        "theme" => list_theme_css,
        "site"  => list_site_css,
      }
    end

    private def list_theme_css : Array(String)
      css_dir = File.join(@config.theme_dir, "static", "css")
      return [] of String unless Dir.exists?(css_dir)

      Dir.glob(File.join(css_dir, "*.css")).map do |path|
        File.basename(path)
      end
    end

    private def list_site_css : Array(String)
      css_dir = File.join(@config.static_dir, "css")
      return [] of String unless Dir.exists?(css_dir)

      Dir.glob(File.join(css_dir, "*.css")).map do |path|
        File.basename(path)
      end
    end
  end
end
