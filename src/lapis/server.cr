require "http/server"
require "file_utils"

module Lapis
  class Server
    property config : Config
    property generator : Generator
    private property server : HTTP::Server?
    private property last_build_time : Time

    def initialize(@config : Config)
      @generator = Generator.new(@config)
      @last_build_time = Time.utc
    end

    def start
      build_initial_site

      server = HTTP::Server.new do |context|
        handle_request(context)
      end

      spawn do
        watch_for_changes
      end

      address = server.bind_tcp(@config.host, @config.port)
      puts "Lapis development server running at http://#{address}"
      puts "Press Ctrl+C to stop"

      server.listen
    end

    private def build_initial_site
      puts "Building initial site..."
      @generator.build
      @last_build_time = Time.utc
      puts "Initial build complete"
    end

    private def handle_request(context : HTTP::Server::Context)
      path = context.request.path

      # Handle live reload endpoint
      if path == "/__lapis_reload__"
        context.response.content_type = "text/plain"
        context.response.print "ok"
        return
      end

      # Normalize path
      if path.ends_with?("/")
        path += "index.html"
      elsif !path.includes?(".")
        path += "/index.html"
      end

      # Remove leading slash for file path
      file_path = File.join(@config.output_dir, path.lstrip("/"))

      if File.exists?(file_path) && File.file?(file_path)
        serve_file(context, file_path)
      else
        serve_404(context)
      end
    end

    private def serve_file(context : HTTP::Server::Context, file_path : String)
      context.response.content_type = mime_type(file_path)

      content = File.read(file_path)

      # Inject live reload script for HTML files
      if file_path.ends_with?(".html")
        content = inject_live_reload_script(content)
      end

      context.response.print(content)
    end

    private def serve_404(context : HTTP::Server::Context)
      context.response.status_code = 404
      context.response.content_type = "text/html"
      context.response.print(not_found_page)
    end

    private def mime_type(file_path : String) : String
      case File.extname(file_path).downcase
      when ".html", ".htm"
        "text/html"
      when ".css"
        "text/css"
      when ".js"
        "application/javascript"
      when ".json"
        "application/json"
      when ".png"
        "image/png"
      when ".jpg", ".jpeg"
        "image/jpeg"
      when ".gif"
        "image/gif"
      when ".svg"
        "image/svg+xml"
      when ".ico"
        "image/x-icon"
      when ".txt"
        "text/plain"
      when ".md"
        "text/markdown"
      else
        "application/octet-stream"
      end
    end

    private def inject_live_reload_script(html : String) : String
      script = <<-JS
      <script>
        (function() {
          let lastCheck = Date.now();

          function checkForChanges() {
            fetch('/__lapis_reload__')
              .then(response => {
                if (response.ok) {
                  const now = Date.now();
                  if (now - lastCheck > 1000) {
                    console.log('Reloading page due to changes...');
                    window.location.reload();
                  }
                }
              })
              .catch(() => {
                // Server might be restarting, try again
              });
          }

          setInterval(checkForChanges, 1000);
          console.log('Lapis live reload enabled');
        })();
      </script>
      JS

      if html.includes?("</body>")
        html.gsub("</body>", "#{script}\n</body>")
      else
        html + script
      end
    end

    private def watch_for_changes
      content_files = [] of String
      layout_files = [] of String
      config_file = "config.yml"

      loop do
        begin
          current_content_files = get_watched_files(@config.content_dir, "*.md")
          current_layout_files = get_watched_files(@config.layouts_dir, "*")

          files_changed = false

          # Check content files
          if current_content_files != content_files
            puts "Content files changed, rebuilding..."
            files_changed = true
            content_files = current_content_files
          end

          # Check layout files
          if current_layout_files != layout_files
            puts "Layout files changed, rebuilding..."
            files_changed = true
            layout_files = current_layout_files
          end

          # Check config file
          if File.exists?(config_file)
            config_mtime = File.info(config_file).modification_time
            if config_mtime > @last_build_time
              puts "Config changed, rebuilding..."
              files_changed = true
              @config = Config.load
              @generator = Generator.new(@config)
            end
          end

          if files_changed
            rebuild_site
          end

          sleep 1.second
        rescue ex
          puts "Error watching files: #{ex.message}"
          sleep 5.seconds
        end
      end
    end

    private def get_watched_files(directory : String, pattern : String) : Array(String)
      files = [] of String
      return files unless Dir.exists?(directory)

      Dir.glob(File.join(directory, "**", pattern)).each do |file_path|
        if File.file?(file_path)
          files << "#{file_path}:#{File.info(file_path).modification_time.to_unix}"
        end
      end

      files.sort
    end

    private def rebuild_site
      begin
        @generator.build
        @last_build_time = Time.utc
        puts "Site rebuilt successfully"
      rescue ex
        puts "Error rebuilding site: #{ex.message}"
      end
    end

    private def not_found_page : String
      <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>404 - Page Not Found</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 600px;
            margin: 100px auto;
            padding: 20px;
            text-align: center;
            color: #333;
          }

          h1 {
            font-size: 4em;
            color: #e74c3c;
            margin-bottom: 20px;
          }

          p {
            font-size: 1.2em;
            margin-bottom: 30px;
          }

          a {
            color: #3498db;
            text-decoration: none;
            font-weight: bold;
          }

          a:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <h1>404</h1>
        <p>The page you're looking for could not be found.</p>
        <p><a href="/">Go back to homepage</a></p>
      </body>
      </html>
      HTML
    end
  end
end