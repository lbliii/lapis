module Lapis
  # Theme helper methods for CSS and asset management
  module ThemeHelpers
    # Build CSS includes with proper cascade priority:
    # 1. Theme base CSS (themes/default/static/css/*.css)
    # 2. Site custom CSS (static/css/*.css)
    # 3. Page-specific CSS (static/css/page-name.css)
    def build_css_includes(page_name : String? = nil) : Array(String)
      css_files = [] of String

      # 1. Theme base CSS - always loaded first
      theme_css_files = discover_theme_css_files
      theme_css_files.each do |css_file|
        css_files << %(<link rel="stylesheet" href="/assets/css/#{File.basename(css_file)}">)
      end

      # 2. Site custom CSS - overrides theme
      site_css_files = discover_site_css_files
      site_css_files.each do |css_file|
        css_files << %(<link rel="stylesheet" href="/assets/css/#{File.basename(css_file)}">)
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

    # Discover all CSS files in theme
    def discover_theme_css_files : Array(String)
      css_files = [] of String
      theme_css_dir = File.join(@config.theme_dir, "static", "css")

      if Dir.exists?(theme_css_dir)
        Dir.glob(File.join(theme_css_dir, "*.css")).each do |file_path|
          css_files << file_path
        end
      end

      css_files.sort
    end

    # Discover all CSS files in site
    def discover_site_css_files : Array(String)
      css_files = [] of String
      site_css_dir = File.join(@config.static_dir, "css")

      if Dir.exists?(site_css_dir)
        Dir.glob(File.join(site_css_dir, "*.css")).each do |file_path|
          css_files << file_path
        end
      end

      css_files.sort
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
