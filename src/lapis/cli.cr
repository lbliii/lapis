require "option_parser"
require "log"
require "json"
require "socket"
require "colorize"
require "./logger"
require "./exceptions"
require "./theme_manager"
require "./config"
require "./pretty_print_utils"

module Lapis
  class CLI
    def initialize(@args : Array(String))
    end

    def run
      raise ArgumentError.new("No command specified") if @args.empty?
      command = @args[0]?
      raise ArgumentError.new("Command cannot be nil") unless command

      # Set up cute logging early
      Logger.setup

      begin
        case command
        when "init"
          init_site
        when "build"
          build_site
        when "serve"
          serve_site
        when "stop"
          stop_server
        when "status"
          server_status
        when "new"
          new_content
        when "theme"
          theme_command
        when "version", "--version", "-v"
          show_version
        when "help", "--help", "-h"
          show_help
        else
          Logger.error("Unknown command", command: command)
          puts "Unknown command: #{command}".colorize(:red).bold
          show_help
          exit(1)
        end
      rescue ex : LapisError
        Logger.error_context("Lapis error: #{ex.message}", ex.context)
        puts "Error: #{ex.message}".colorize(:red).bold
        exit(1)
      rescue ex
        Logger.fatal("Unexpected error", error: ex.message)
        puts "Unexpected error: #{ex.message}".colorize(:red).bold
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
          puts "Error: Template name and site name required".colorize(:red).bold
          puts ""
          PrettyPrintUtils.format_help_section("Usage:", "lapis init --template <template-name> <site-name>\nlapis init --template list")
          exit(1)
        end

        TemplateManager.create_from_template(template_name, site_name)
        return
      end

      site_name = @args[1]?
      unless site_name
        puts "Error: Site name required".colorize(:red).bold
        puts ""
        PrettyPrintUtils.format_help_section("Usage:", "lapis init <site-name>\nlapis init --template <template-name> <site-name>\nlapis init --template list")
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
        puts "Error: Directory '#{site_name}' already exists".colorize(:red).bold
        exit(1)
      end
    end

    private def build_site
      Logger.info("Starting CLI build process")
      config = Config.load
      Logger.debug("Config loaded",
        incremental: config.build_config.incremental?,
        parallel: config.build_config.parallel?,
        cache_dir: config.build_config.cache_dir)

      generator = Generator.new(config)
      Logger.info("Generator created, calling build_with_analytics")

      # Use analytics-enabled build
      generator.build_with_analytics
      Logger.info("Build completed successfully")

      puts "Site built successfully in '#{config.output_dir}'".colorize(:green).bold
    end

    private def serve_site
      # Parse serve command arguments
      auto_open = @args.includes?("--open") || @args.includes?("-o")
      port_arg = @args.index("--port").try { |i| @args[i + 1]?.try(&.to_i?) }

      config = Config.load

      # Override port if specified
      if port_arg
        config.port = port_arg
      end

      # Check for port conflicts
      if port_in_use?(config.port)
        puts "⚠️  Port #{config.port} is already in use!".colorize(:yellow).bold
        puts ""

        # Show what's using the port
        show_port_usage(config.port)

        # Offer solutions
        puts "Options:".colorize(:cyan)
        puts "  1. Stop the existing server: lapis stop"
        puts "  2. Use a different port: lapis serve --port <port>"
        puts "  3. Start with auto-open: lapis serve --open --port <port>"
        puts "  4. Kill processes using port #{config.port}"
        puts ""

        print "Continue anyway? [y/N]: ".colorize(:yellow)
        response = gets.try(&.strip.downcase)
        unless response == "y" || response == "yes"
          puts "Server startup cancelled.".colorize(:yellow)
          exit(0)
        end
        puts ""
      end

      puts "🚀 Starting development server...".colorize(:green).bold

      # Show clickable server URL
      server_url = "http://#{config.host}:#{config.port}"
      puts "📍 Server will be available at: #{server_url}".colorize(:cyan)
      puts "   💡 Click the link above or copy-paste it into your browser".colorize(:dim)

      # Open browser automatically if requested or ask user
      if auto_open
        puts "   🚀 Opening browser automatically...".colorize(:green)
        spawn open_in_browser(server_url)
      else
        print "   🚀 Open in browser automatically? [Y/n]: ".colorize(:yellow)
        response = gets.try(&.strip.downcase)
        if response.nil? || response.empty? || response == "y" || response == "yes"
          spawn open_in_browser(server_url)
        end
      end

      # Save server info for management
      save_server_info(config.port, config.host)

      begin
        server = Server.new(config)

        # Set up signal handlers for graceful shutdown
        setup_signal_handlers(config.port)

        server.start
      rescue ex
        cleanup_server_info(config.port)
        puts "❌ Failed to start server: #{ex.message}".colorize(:red).bold
        exit(1)
      end
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

    private def stop_server
      force = @args.includes?("--force") || @args.includes?("-f")
      port_arg = @args.index("--port").try { |i| @args[i + 1]?.try(&.to_i?) }

      if port_arg
        # Stop server on specific port
        stop_server_on_port(port_arg, force)
      else
        # Stop all Lapis servers
        stop_all_servers(force)
      end
    end

    private def server_status
      puts "🔍 Checking Lapis server status..."
      puts ""

      servers = find_running_servers
      if servers.empty?
        puts "No Lapis servers are currently running."
        puts ""
        puts "💡 Start a server with: lapis serve"
        return
      end

      puts "Running Lapis servers:"
      servers.each do |server_info|
        status_icon = server_info[:responding].as(Bool) ? "🟢" : "🔴"
        port = server_info[:port].as(Int32)
        host = server_info[:host]? || "localhost"
        server_url = "http://#{host}:#{port}"

        puts "  #{status_icon} Port #{port} (PID: #{server_info[:pid]})"
        puts "     🌐 #{server_url}".colorize(:cyan)
        puts "     💡 Click the link above to open in browser".colorize(:dim)

        if config_file = server_info[:config_file]
          puts "     📄 Config: #{config_file}"
        end
        if project_dir = server_info[:project_dir]
          puts "     📁 Project: #{project_dir}"
        end
        puts ""
      end

      puts "Commands:"
      puts "  lapis stop           Stop all servers"
      puts "  lapis stop --port N  Stop server on specific port"
      puts "  lapis stop --force   Force kill all servers"
    end

    private def theme_command
      subcommand = @args[1]?

      unless subcommand
        show_theme_help
        return
      end

      begin
        case subcommand
        when "list"
          list_themes
        when "info"
          theme_info
        when "install"
          install_theme
        when "validate"
          validate_theme
        when "help", "--help", "-h"
          show_theme_help
        else
          puts "Unknown theme command: #{subcommand}"
          show_theme_help
          exit(1)
        end
      rescue ex : ThemeError
        puts "Theme Error: #{ex.message}"
        exit(1)
      end
    end

    private def list_themes
      config = Config.load
      theme_manager = ThemeManager.new(config.theme, config.root_dir)

      puts "Available themes:"
      puts ""

      available_themes = theme_manager.list_available_themes

      if available_themes.empty?
        puts "  No themes found."
        puts ""
        puts "💡 Tip: Install themes from shards with 'lapis theme install <theme-name>'".colorize(:cyan)
        return
      end

      # Group by source type
      local_themes = available_themes.select { |_, source| source == "local" }
      shard_themes = available_themes.select { |_, source| source == "shard" }
      global_themes = available_themes.select { |_, source| source == "global" }

      unless local_themes.empty?
        puts "  📁 Local themes (themes/ directory):"
        local_themes.each { |name, _| puts "    #{name}" }
        puts ""
      end

      unless shard_themes.empty?
        puts "  📦 Shard themes (lib/ directory):"
        shard_themes.each { |name, _| puts "    #{name}" }
        puts ""
      end

      unless global_themes.empty?
        puts "  🌍 Global themes (~/.lapis/themes/):"
        global_themes.each { |name, _| puts "    #{name}" }
        puts ""
      end

      puts "Current theme: #{config.theme}"

      if theme_manager.theme_available?
        puts "✅ Current theme is available".colorize(:green)
      else
        puts "❌ Current theme is not available".colorize(:red).bold
      end
    end

    private def theme_info
      theme_name = @args[2]?

      unless theme_name
        puts "❌ Error: Theme name required".colorize(:red).bold.colorize(:red).bold
        puts ""
        puts "Usage: lapis theme info <theme-name>"
        puts ""
        puts "Examples:"
        puts "  lapis theme info my-theme"
        puts "  lapis theme info default"
        puts ""
        puts "💡 Tip: Run 'lapis theme list' to see available themes".colorize(:cyan)
        exit(1)
      end

      begin
        config = Config.load
        theme_manager = ThemeManager.new(theme_name, config.root_dir)

        unless theme_manager.theme_exists?(theme_name)
          puts "❌ Theme '#{theme_name}' not found".colorize(:red).bold
          puts ""
          puts "Available themes:"
          available_themes = theme_manager.list_available_themes
          if available_themes.empty?
            puts "  No themes found"
          else
            available_themes.each do |name, source|
              puts "  📦 #{name} (#{source})"
            end
          end
          puts ""
          puts "💡 Tip: Install themes with 'lapis theme install <theme-name>'".colorize(:cyan)
          exit(1)
        end
      rescue ex : LapisError
        puts "❌ Configuration Error: #{ex.message}".colorize(:red).bold
        puts ""
        puts "💡 Make sure you're in a Lapis project directory with a valid config.yml".colorize(:cyan)
        exit(1)
      rescue ex
        puts "❌ Unexpected Error: #{ex.message}".colorize(:red).bold
        exit(1)
      end

      puts "Theme: #{theme_name}"
      puts "Source: #{theme_manager.theme_source(theme_name)}"
      puts ""

      # Show theme info if available
      info = theme_manager.theme_info
      unless info.empty?
        puts "Theme Information:"
        info.each do |key, value|
          puts "  #{key.capitalize}: #{value}"
        end
        puts ""
      end

      # Validate theme
      theme_paths = theme_manager.theme_paths
      if theme_path = theme_paths.first?
        validation = theme_manager.validate_theme(theme_path)

        puts "Validation:"
        puts "  Valid: #{validation["valid"]? ? "✅" : "❌"}"
        puts "  Has layouts: #{validation["has_layouts"]? ? "✅" : "❌"}"
        puts "  Has base template: #{validation["has_baseof"]? ? "✅" : "❌"}"
        puts "  Has default layout: #{validation["has_default_layout"]? ? "✅" : "❌"}"
        puts "  Has theme config: #{validation["has_theme_config"]? ? "✅" : "❌"}"

        if error = validation["error"]?.try(&.as(String))
          unless error.empty?
            puts "  Error: #{error}"
          end
        end
      end
    end

    private def install_theme
      theme_name = @args[2]?

      unless theme_name
        puts "❌ Error: Theme name required".colorize(:red).bold
        puts ""
        puts "Usage: lapis theme install <theme-name>"
        puts ""
        puts "Examples:"
        puts "  lapis theme install awesome-blog-theme"
        puts "  lapis theme install lapis-theme-minimal"
        puts ""
        puts "💡 Tip: Theme names typically start with 'lapis-theme-'".colorize(:cyan)
        exit(1)
      end

      puts "Installing theme: #{theme_name}"
      puts ""
      puts "💡 Theme installation via shards:"
      puts "1. Add the theme to your shard.yml file:"
      puts "   dependencies:"
      puts "     #{theme_name}:"
      puts "       github: username/#{theme_name}"
      puts ""
      puts "2. Run: shards install"
      puts ""
      puts "3. Update your config.yml:"
      puts "   theme: #{theme_name}"
      puts ""
      puts "Note: Automated shard installation will be added in a future release."
    end

    private def validate_theme
      theme_name = @args[2]?

      unless theme_name
        puts "❌ Error: Theme name required".colorize(:red).bold
        puts ""
        puts "Usage: lapis theme validate <theme-name>"
        puts ""
        puts "Examples:"
        puts "  lapis theme validate my-theme"
        puts "  lapis theme validate default"
        puts ""
        puts "💡 Tip: Run 'lapis theme list' to see available themes"
        exit(1)
      end

      begin
        config = Config.load
        theme_manager = ThemeManager.new(theme_name, config.root_dir)

        unless theme_manager.theme_exists?(theme_name)
          puts "❌ Theme '#{theme_name}' not found".colorize(:red).bold
          puts ""
          puts "Available themes:"
          available_themes = theme_manager.list_available_themes
          if available_themes.empty?
            puts "  No themes found"
          else
            available_themes.each do |name, source|
              puts "  📦 #{name} (#{source})"
            end
          end
          puts ""
          puts "💡 Tip: Install themes with 'lapis theme install <theme-name>'".colorize(:cyan)
          exit(1)
        end

        theme_paths = theme_manager.theme_paths
        unless theme_path = theme_paths.first?
          puts "❌ Internal Error: No theme path found for '#{theme_name}'".colorize(:red).bold
          puts "This shouldn't happen if the theme exists. Please report this as a bug."
          exit(1)
        end
      rescue ex : LapisError
        puts "❌ Configuration Error: #{ex.message}".colorize(:red).bold
        puts ""
        puts "💡 Make sure you're in a Lapis project directory with a valid config.yml".colorize(:cyan)
        exit(1)
      rescue ex
        puts "❌ Unexpected Error: #{ex.message}".colorize(:red).bold
        exit(1)
      end

      puts "Validating theme: #{theme_name}"
      puts "Path: #{theme_path}"
      puts ""

      # Determine validation method based on source
      source = theme_manager.theme_source(theme_name)
      validation = if source == "shard"
                     theme_manager.validate_shard_theme(theme_path)
                   else
                     theme_manager.validate_theme(theme_path)
                   end

      if validation["valid"].as(Bool)
        puts "✅ Theme is valid!".colorize(:green).bold
      else
        puts "❌ Theme validation failed".colorize(:red).bold
        if error = validation["error"]?.try(&.as(String))
          unless error.empty?
            puts "Error: #{error}"
          end
        end
      end

      puts ""
      puts "Validation details:"
      puts "  Has layouts directory: #{validation["has_layouts"]? ? "✅" : "❌"}"
      puts "  Has base template: #{validation["has_baseof"]? ? "✅" : "❌"}"
      puts "  Has default layout: #{validation["has_default_layout"]? ? "✅" : "❌"}"
      puts "  Has theme config: #{validation["has_theme_config"]? ? "✅" : "❌"}"
    end

    private def show_theme_help
      puts "Lapis theme management"
      puts ""
      puts "Usage: lapis theme <command> [options]"
      puts ""
      puts "Commands:"
      puts "  list                    List all available themes"
      puts "  info <theme-name>       Show detailed theme information"
      puts "  install <theme-name>    Show instructions for installing a theme"
      puts "  validate <theme-name>   Validate a theme's structure"
      puts "  help                    Show this help"
      puts ""
      puts "Examples:"
      puts "  lapis theme list"
      puts "  lapis theme info my-theme"
      puts "  lapis theme install awesome-blog-theme"
      puts "  lapis theme validate my-theme"
    end

    # Server management helper methods
    private def port_in_use?(port : Int32) : Bool
      raise ArgumentError.new("Port must be between 1 and 65535") unless (1..65535).includes?(port)
      result = `lsof -ti:#{port} 2>/dev/null`.strip
      !result.empty?
    end

    private def show_port_usage(port : Int32)
      result = `lsof -n -P -i:#{port} 2>/dev/null`
      unless result.strip.empty?
        puts "Processes using port #{port}:"
        puts result
        puts ""
      end
    end

    private def save_server_info(port : Int32, host : String)
      server_info = {
        "pid"         => Process.pid,
        "port"        => port,
        "host"        => host,
        "started_at"  => Time.utc.to_s,
        "project_dir" => Dir.current,
        "config_file" => File.exists?("config.yml") ? File.expand_path("config.yml") : nil,
      }

      servers_dir = File.expand_path("~/.lapis/servers")
      Dir.mkdir_p(servers_dir)

      info_file = File.join(servers_dir, "#{port}.json")
      File.write(info_file, server_info.to_json)
    end

    private def cleanup_server_info(port : Int32)
      servers_dir = File.expand_path("~/.lapis/servers")
      info_file = File.join(servers_dir, "#{port}.json")
      File.delete(info_file) if File.exists?(info_file)
    end

    private def setup_signal_handlers(port : Int32)
      # Skip signal handling in test mode
      return if ENV.fetch("LAPIS_TEST_MODE", "false") == "true"

      # Use Process.on_terminate for modern signal handling
      Process.on_terminate do |reason|
        case reason
        when .interrupted?
          puts "\n🛑 Received interrupt signal, shutting down gracefully..."
          cleanup_server_info(port)
          exit(0)
        when .terminal_disconnected?
          puts "\n🛑 Terminal disconnected, shutting down gracefully..."
          cleanup_server_info(port)
          exit(0)
        when .session_ended?
          puts "\n🛑 Session ended, shutting down gracefully..."
          cleanup_server_info(port)
          exit(0)
        end
      end
    end

    private def stop_server_on_port(port : Int32, force : Bool = false)
      puts "🛑 Stopping server on port #{port}..."

      pids = `lsof -ti:#{port} 2>/dev/null`.strip.split('\n').compact_map(&.to_i?)

      if pids.empty?
        puts "No server found running on port #{port}"
        return
      end

      pids.each do |pid|
        if force
          puts "Force killing process #{pid}..."
          `kill -9 #{pid} 2>/dev/null`
        else
          puts "Gracefully stopping process #{pid}..."
          `kill -15 #{pid} 2>/dev/null`

          # Wait a bit for graceful shutdown
          sleep(2.seconds)

          # Check if still running
          if process_running?(pid)
            puts "Process didn't stop gracefully, force killing..."
            `kill -9 #{pid} 2>/dev/null`
          end
        end
      end

      cleanup_server_info(port)
      puts "✅ Server on port #{port} stopped"
    end

    private def stop_all_servers(force : Bool = false)
      servers = find_running_servers

      if servers.empty?
        puts "No Lapis servers are currently running"
        return
      end

      puts "🛑 Stopping #{servers.size} Lapis server(s)..."

      servers.each do |server|
        stop_server_on_port(server[:port].as(Int32), force)
      end

      puts "✅ All Lapis servers stopped"
    end

    private def find_running_servers
      servers = [] of Hash(Symbol, String | Int32 | Bool | Nil)
      servers_dir = File.expand_path("~/.lapis/servers")

      return servers unless Dir.exists?(servers_dir)

      Dir.each_child(servers_dir) do |file|
        next unless file.ends_with?(".json")

        info_file = File.join(servers_dir, file)
        begin
          info = JSON.parse(File.read(info_file))
          pid = info["pid"].as_i
          port = info["port"].as_i

          if process_running?(pid)
            servers << {
              :pid         => pid,
              :port        => port,
              :host        => info["host"].as_s,
              :project_dir => info["project_dir"]?.try(&.as_s),
              :config_file => info["config_file"]?.try(&.as_s),
              :responding  => port_responding?(port),
            }
          else
            # Clean up stale server info
            File.delete(info_file)
          end
        rescue
          # Clean up invalid server info files
          File.delete(info_file) if File.exists?(info_file)
        end
      end

      servers
    end

    private def process_running?(pid : Int32) : Bool
      # Check if process exists by sending signal 0
      result = `kill -0 #{pid} 2>/dev/null`
      $?.success?
    end

    private def port_responding?(port : Int32) : Bool
      # Enhanced port check with timeout and proper Socket error handling
      socket = TCPSocket.new("localhost", port)
      socket.close
      true
    rescue Socket::ConnectError
      # Port is not responding - likely not in use
      false
    rescue Socket::Error | IO::TimeoutError
      # Socket errors or timeout - port might be in use or unreachable
      true
    rescue
      # Any other error - assume port is in use
      true
    end

    private def socket_health_check(host : String, port : Int32) : Hash(String, Bool | String)
      # Comprehensive socket health check with detailed diagnostics
      result = {
        "reachable"     => false,
        "error"         => nil,
        "response_time" => nil,
      } of String => Bool | String

      start_time = Time.monotonic

      begin
        socket = TCPSocket.new(host, port)

        # Test if we can actually communicate
        socket.puts "GET / HTTP/1.1\r\nHost: #{host}\r\nConnection: close\r\n\r\n"

        response_time = Time.monotonic - start_time
        result["reachable"] = true
        result["response_time"] = "#{response_time.total_milliseconds}ms"

        socket.close
      rescue Socket::ConnectError
        result["error"] = "Connection refused"
      rescue Socket::Error
        result["error"] = "Socket error"
      rescue IO::TimeoutError
        result["error"] = "Connection timeout"
      rescue ex
        result["error"] = "Unexpected error: #{ex.message}"
      end

      result
    end

    private def show_version
      puts DESCRIPTION
    end

    private def open_in_browser(url : String)
      # Cross-platform browser opening
      case
      when system("which open > /dev/null 2>&1")
        system("open #{url}")
      when system("which xdg-open > /dev/null 2>&1")
        system("xdg-open #{url}")
      when system("which start > /dev/null 2>&1")
        system("start #{url}")
      else
        puts "   ⚠️  Could not automatically open browser. Please open #{url} manually.".colorize(:yellow)
      end
    end

    private def show_help
      puts DESCRIPTION
      puts ""

      PrettyPrintUtils.format_help_section("Usage", "lapis [command] [options]")

      PrettyPrintUtils.format_help_section("Commands",
        "init <name>         Create a new site\n" +
        "build               Build the site\n" +
        "serve               Start development server (with live reload)\n" +
        "stop                Stop running development servers\n" +
        "status              Show running server status\n" +
        "new [type] <title>  Create new content (page or post)\n" +
        "theme <command>     Theme management commands\n" +
        "version             Show version information\n" +
        "help                Show this help"
      )

      PrettyPrintUtils.format_help_section("Examples",
        "lapis init my-blog\n" +
        "lapis new post \"My First Post\"\n" +
        "lapis build\n" +
        "lapis serve\n" +
        "lapis stop\n" +
        "lapis status\n" +
        "lapis theme list\n" +
        "lapis theme install <theme-name>"
      )

      PrettyPrintUtils.format_help_section("Server Management",
        "lapis serve --port 4000   Start server on specific port\n" +
        "lapis serve --open        Start server and open browser automatically\n" +
        "lapis serve -o            Short form of --open\n" +
        "lapis stop --port 3000    Stop server on specific port\n" +
        "lapis stop --force        Force kill all servers\n" +
        "lapis status              Show all running servers"
      )

      PrettyPrintUtils.format_help_section("Environment Variables",
        "LAPIS_LOG_LEVEL          Set logging level (debug, info, warn, error)\n" +
        "LAPIS_ENV                Set environment (development, production)\n" +
        "LAPIS_BUILD_DRAFTS       Include drafts in builds (true/false)\n" +
        "LAPIS_SERVER             Enable server mode (true/false)\n" +
        "LAPIS_PORT               Override server port\n" +
        "LAPIS_HOST               Override server host\n" +
        "LAPIS_OUTPUT_DIR         Override output directory\n" +
        "LAPIS_CACHE_DIR          Override cache directory\n" +
        "LAPIS_DEBUG              Enable debug mode (true/false)\n" +
        "LAPIS_THEME              Override theme\n" +
        "LAPIS_TEST_MODE          Disable signal handlers (true/false)"
      )

      PrettyPrintUtils.format_help_section("Environment Examples",
        "LAPIS_LOG_LEVEL=debug lapis build\n" +
        "LAPIS_PORT=4000 lapis serve\n" +
        "LAPIS_BUILD_DRAFTS=true lapis build"
      )
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
