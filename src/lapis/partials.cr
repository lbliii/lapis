require "./function_processor"

module Lapis
  # Partials system for reusable template components
  # Usage: {{ partial "head" . }} or {{ partial "header" . }}
  module Partials

    # Process partial function calls in templates
    def self.process_partials(template : String, context : TemplateContext, theme_dir : String) : String
      result = template

      # Process all {{ partial "name" . }} calls
      result = result.gsub(/\{\{\s*partial\s+"([^"]+)"\s+\.\s*\}\}/) do |match|
        partial_name = $1
        render_partial(partial_name, context, theme_dir)
      end

      result
    end

    # Render a specific partial template
    def self.render_partial(name : String, context : TemplateContext, theme_dir : String) : String
      partial_path = find_partial(name, theme_dir)

      if partial_path && File.exists?(partial_path)
        partial_content = read_partial_file(partial_path)

        # Process the partial content with context
        process_partial_content(partial_content, context, theme_dir)
      else
        # Fallback to built-in partial if custom one doesn't exist
        generate_builtin_partial(name, context)
      end
    end

    # Find partial file with theme hierarchy
    def self.find_partial(name : String, theme_dir : String) : String?
      # Try site-specific partials first
      site_partial = File.join("layouts", "partials", "#{name}.html")
      return site_partial if File.exists?(site_partial)

      # Try theme partials
      theme_partial = File.join(theme_dir, "layouts", "partials", "#{name}.html")
      return theme_partial if File.exists?(theme_partial)

      nil
    end

    # Process partial content with template variables
    def self.process_partial_content(content : String, context : TemplateContext, theme_dir : String) : String
      # Process nested partials first
      result = process_partials(content, context, theme_dir)

      # Use the advanced function processor for advanced template syntax
      function_processor = FunctionProcessor.new(context)
      result = function_processor.process(result)

      # Auto CSS discovery (legacy support)
      result = result.gsub("{{ auto_css }}", generate_auto_css(context))

      result
    end

    # Legacy method kept for compatibility but deprecated
    def self.process_template_variables(content : String, context : TemplateContext) : String
      # This method is deprecated - use FunctionProcessor instead
      content
    end

    # Generate built-in partials when custom ones don't exist
    def self.generate_builtin_partial(name : String, context : TemplateContext) : String
      case name
      when "head"
        generate_head_partial(context)
      when "header"
        generate_header_partial(context)
      when "footer"
        generate_footer_partial(context)
      when "nav", "navigation"
        generate_nav_partial(context)
      else
        ""
      end
    end

    # Built-in head partial with automatic CSS discovery
    def self.generate_head_partial(context : TemplateContext) : String
      <<-HTML
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>{{ title }} - {{ site.title }}</title>
      <meta name="description" content="{{ description }}">

      #{generate_auto_css(context)}
      HTML
    end

    # Built-in header partial
    def self.generate_header_partial(context : TemplateContext) : String
      <<-HTML
      <header class="site-header">
        <nav class="site-nav">
          <a href="/" class="site-title">{{ site.title }}</a>
          <div class="nav-links">
            <a href="/">Home</a>
            <a href="/posts/">Posts</a>
            <a href="/about/">About</a>
          </div>
        </nav>
      </header>
      HTML
    end

    # Built-in footer partial
    def self.generate_footer_partial(context : TemplateContext) : String
      <<-HTML
      <footer class="site-footer">
        <p>&copy; {{ site.title }} - Built with <a href="https://github.com/lapis-lang/lapis">Lapis</a></p>
      </footer>
      HTML
    end

    # Built-in navigation partial
    def self.generate_nav_partial(context : TemplateContext) : String
      <<-HTML
      <nav class="site-nav">
        <a href="/" class="site-title">{{ site.title }}</a>
        <div class="nav-links">
          <a href="/">Home</a>
          <a href="/posts/">Posts</a>
          <a href="/about/">About</a>
        </div>
      </nav>
      HTML
    end

    # Automatic CSS discovery - advanced asset pipeline
    def self.generate_auto_css(context : TemplateContext) : String
      css_files = [] of String

      # 1. Theme CSS - check for style.css in theme
      theme_css_path = File.join(context.config.theme_dir, "static", "css", "style.css")
      if File.exists?(theme_css_path)
        css_files << %(<link rel="stylesheet" href="/assets/css/style.css">)
      end

      # 2. Site custom CSS - check for custom.css in site
      site_css_path = File.join(context.config.static_dir, "css", "custom.css")
      if File.exists?(site_css_path)
        css_files << %(<link rel="stylesheet" href="/assets/css/custom.css">)
      end

      # 3. Auto-discover additional CSS files in static/css/
      css_dir = File.join(context.config.static_dir, "css")
      if Dir.exists?(css_dir)
        Dir.glob(File.join(css_dir, "*.css")).each do |css_file|
          filename = File.basename(css_file)
          # Skip files we already included
          next if filename == "custom.css"
          css_files << %(<link rel="stylesheet" href="/assets/css/#{filename}">)
        end
      end

      css_files.join("\n  ")
    end

    private def self.read_partial_file(file_path : String) : String
      File.open(file_path, "r") do |file|
        file.set_encoding("UTF-8")
        file.gets_to_end
      end
    rescue ex : File::NotFoundError
      raise "Partial file not found: #{file_path}"
    rescue ex : IO::Error
      raise "Error reading partial file #{file_path}: #{ex.message}"
    end
  end
end