require "option_parser"
require "log"
require "./logger"
require "./exceptions"

module Lapis
  class CLI
    def initialize(@args : Array(String))
    end

    def run
      command = @args[0]? || "help"

      begin
        case command
        when "init"
          init_site
        when "build"
          build_site
        when "serve"
          serve_site
        when "new"
          new_content
        when "help", "--help", "-h"
          show_help
        else
          Logger.error("Unknown command", command: command)
          puts "Unknown command: #{command}"
          show_help
          exit(1)
        end
      rescue ex : LapisError
        Logger.error("Lapis error", error: ex.message, context: ex.context)
        puts "Error: #{ex.message}"
        exit(1)
      rescue ex
        Logger.fatal("Unexpected error", error: ex.message)
        puts "Unexpected error: #{ex.message}"
        exit(1)
      end
    end

    private def init_site
      # Check for template flag
      if @args[1]? == "--template" || @args[1]? == "-t"
        if @args[2]? == "list"
          TemplateManager.list_templates
          return
        end

        template_name = @args[2]?
        site_name = @args[3]?

        unless template_name && site_name
          puts "Error: Template name and site name required"
          puts "Usage: lapis init --template <template-name> <site-name>"
          puts "       lapis init --template list"
          exit(1)
        end

        TemplateManager.create_from_template(template_name, site_name)
        return
      end

      site_name = @args[1]?
      unless site_name
        puts "Error: Site name required"
        puts "Usage: lapis init <site-name>"
        puts "       lapis init --template <template-name> <site-name>"
        puts "       lapis init --template list"
        exit(1)
      end

      puts "Creating new site: #{site_name}"

      begin
        Dir.mkdir(site_name)
        Dir.cd(site_name) do
          create_site_structure
          puts "Site '#{site_name}' created successfully!"
          puts ""
          puts "Next steps:"
          puts "  cd #{site_name}"
          puts "  lapis serve"
          puts ""
          puts "💡 Tip: Try 'lapis init --template list' to see available templates"
        end
      rescue File::AlreadyExistsError
        puts "Error: Directory '#{site_name}' already exists"
        exit(1)
      end
    end

    private def build_site
      Logger.info("Starting CLI build process")
      config = Config.load
      Logger.debug("Config loaded",
        incremental: config.build_config.incremental,
        parallel: config.build_config.parallel,
        cache_dir: config.build_config.cache_dir)

      generator = Generator.new(config)
      Logger.info("Generator created, calling build_with_analytics")

      # Use analytics-enabled build
      generator.build_with_analytics
      Logger.info("Build completed successfully")

      puts "Site built successfully in '#{config.output_dir}'"
    end

    private def serve_site
      puts "Starting development server..."
      config = Config.load
      server = Server.new(config)
      server.start
    end

    private def new_content
      content_type = @args[1]? || "page"
      title = @args[2]?

      unless title
        puts "Error: Content title required"
        puts "Usage: lapis new [page|post] <title>"
        exit(1)
      end

      puts "Creating new #{content_type}: #{title}"
      Content.create_new(content_type, title)
    end

    private def show_help
      puts "Lapis static site generator v#{VERSION}"
      puts ""
      puts "Usage: lapis [command] [options]"
      puts ""
      puts "Commands:"
      puts "  init <name>         Create a new site"
      puts "  build               Build the site"
      puts "  serve               Start development server (with live reload)"
      puts "  new [type] <title>  Create new content (page or post)"
      puts "  help                Show this help"
      puts ""
      puts "Examples:"
      puts "  lapis init my-blog"
      puts "  lapis new post \"My First Post\""
      puts "  lapis build"
      puts "  lapis serve"
    end

    private def create_site_structure
      # Create directories
      ["content", "content/posts", "layouts", "static", "static/css", "static/js"].each do |dir|
        Dir.mkdir_p(dir)
      end

      # Create config file
      config_content = <<-YAML
      title: "My Lapis Site"
      baseurl: "http://localhost:3000"
      description: "A site built with Lapis"
      author: "Your Name"

      # Build settings
      output_dir: "public"
      permalink: "/:year/:month/:day/:title/"

      # Server settings
      port: 3000
      host: "localhost"

      # Markdown settings
      markdown:
        syntax_highlighting: true
        toc: true
      YAML

      File.write("config.yml", config_content)

      # Create a sample index page
      index_content = <<-MD
      ---
      title: "Welcome to Lapis"
      layout: "default"
      ---

      # Welcome to your new Lapis site!

      This is your homepage. Edit this file in `content/index.md` to get started.

      ## Getting Started

      1. Create new content with `lapis new page "About"`
      2. Write posts with `lapis new post "My First Post"`
      3. Build your site with `lapis build`
      4. Serve it locally with `lapis serve`

      Enjoy building with Lapis!
      MD

      File.write("content/index.md", index_content)

      # Create a sample post
      post_content = <<-MD
      ---
      title: "Welcome to Lapis"
      date: "#{Time.utc.to_s(Lapis::DATE_FORMAT)}"
      tags: ["welcome", "lapis"]
      layout: "post"
      ---

      # Welcome to Lapis!

      This is your first post. You can edit it or delete it and create your own posts.

      ## Features

      - Fast static site generation
      - Markdown support with frontmatter
      - Live reload development server
      - Flexible templating system
      - Built-in themes

      Happy blogging!
      MD

      File.write("content/posts/welcome.md", post_content)

      puts "Created site structure with sample content"
    end
  end
end
