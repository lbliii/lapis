require "http/server"
require "file_utils"

module Lapis
  class Server
    property config : Config
    property generator : Generator
    property live_reload : LiveReload
    private property server : HTTP::Server?
    private property last_build_time : Time

    def initialize(@config : Config)
      @generator = Generator.new(@config)
      @last_build_time = Time.utc
      @live_reload = LiveReload.new(@config, @generator)
    end

    def start
      build_initial_site
      @live_reload.start

      server = HTTP::Server.new do |context|
        handle_request(context)
      end

      address = server.bind_tcp(@config.host, @config.port)
      puts "Lapis development server running at http://#{address}"
      puts "Live reload enabled with WebSocket support"
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

      # Handle WebSocket upgrade for live reload
      if @live_reload.handle_websocket_upgrade(context)
        return
      end

      # Legacy live reload endpoint (kept for backward compatibility)
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

      begin
        File.open(file_path, "r") do |file|
          file.set_encoding("UTF-8")
          
          # For HTML files, we need to inject live reload script
          if file_path.ends_with?(".html")
            content = file.gets_to_end
            content = inject_live_reload_script(content)
            context.response.print(content)
          else
            # For other files, stream directly for better memory efficiency
            IO.copy(file, context.response)
          end
        end
      rescue ex : File::NotFoundError
        serve_404(context)
      rescue ex : IO::Error
        puts "Error serving file #{file_path}: #{ex.message}"
        serve_404(context)
      end
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
          let socket = null;
          let reconnectAttempts = 0;
          const maxReconnectAttempts = 10;
          const reconnectDelay = 1000;

          function connect() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${window.location.host}/__lapis_live_reload__`;
            
            try {
              socket = new WebSocket(wsUrl);
              
              socket.onopen = function() {
                console.log('Lapis live reload connected');
                reconnectAttempts = 0;
              };
              
              socket.onmessage = function(event) {
                try {
                  const data = JSON.parse(event.data);
                  handleReloadMessage(data);
                } catch (e) {
                  console.error('Failed to parse reload message:', e);
                }
              };
              
              socket.onclose = function() {
                console.log('Lapis live reload disconnected');
                attemptReconnect();
              };
              
              socket.onerror = function(error) {
                console.log('Lapis live reload error:', error);
              };
            } catch (error) {
              console.error('Failed to create WebSocket connection:', error);
              attemptReconnect();
            }
          }

          function attemptReconnect() {
            if (reconnectAttempts < maxReconnectAttempts) {
              reconnectAttempts++;
              console.log(`Attempting to reconnect... (${reconnectAttempts}/${maxReconnectAttempts})`);
              setTimeout(connect, reconnectDelay * reconnectAttempts);
            } else {
              console.log('Max reconnection attempts reached. Live reload disabled.');
            }
          }

          function handleReloadMessage(data) {
            console.log('Reload message received:', data);
            
            switch(data.type) {
              case 'full_reload':
                console.log('Reloading page due to changes...');
                window.location.reload();
                break;
                
              case 'css_reload':
                console.log('Reloading CSS files...');
                reloadCSS(data.files || []);
                break;
                
              case 'js_reload':
                console.log('Reloading JS files...');
                reloadJS(data.files || []);
                break;
                
              default:
                console.log('Unknown reload type:', data.type);
                window.location.reload();
            }
          }

          function reloadCSS(files) {
            // Reload CSS files by adding timestamp to href
            const links = document.querySelectorAll('link[rel="stylesheet"]');
            links.forEach(link => {
              const href = link.getAttribute('href');
              if (href && (files.length === 0 || files.some(file => href.includes(file)))) {
                const url = new URL(href, window.location.href);
                url.searchParams.set('_t', Date.now().toString());
                link.setAttribute('href', url.toString());
              }
            });
          }

          function reloadJS(files) {
            // For JS files, we'll do a full page reload for now
            // In the future, we could implement module reloading
            console.log('JS files changed, reloading page...');
            window.location.reload();
          }

          // Start the connection
          connect();
        })();
      </script>
      JS

      if html.includes?("</body>")
        html.gsub("</body>", "#{script}\n</body>")
      else
        html + script
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