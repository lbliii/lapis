require "http/server"
require "file_utils"
require "log"
require "./logger"
require "./exceptions"

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
      Logger.setup(@config)
      Logger.build_operation("Starting development server")

      build_initial_site
      @live_reload.start

      server = HTTP::Server.new do |context|
        handle_request(context)
      end

      begin
        # Configure socket options if available
        configure_server_socket(server) if server.responds_to?(:socket)

        address = server.bind_tcp(@config.host, @config.port)

        # Display server URL with clickable link
        server_url = "http://#{@config.host}:#{@config.port}"
        puts "\n🎉 Server is running!".colorize(:green).bold
        puts "🌐 Open your site: #{server_url}".colorize(:cyan).bold
        puts "   💡 Click the link above or copy-paste it into your browser".colorize(:dim)
        puts ""

        Logger.info("Development server started", host: @config.host, port: @config.port.to_s, url: server_url)
        Logger.info("Socket options",
          reuse_address: @config.socket_reuse_address,
          keepalive: @config.socket_keepalive,
          timeout: @config.socket_timeout,
          send_buffer: @config.socket_send_buffer_size,
          recv_buffer: @config.socket_recv_buffer_size)
        Logger.info("Live reload enabled with WebSocket support")
        Logger.info("Press Ctrl+C to stop")

        server.listen
      rescue ex : Socket::BindError
        Logger.fatal("Failed to bind server", host: @config.host, port: @config.port.to_s, error: ex.message)
        raise ServerError.new("Failed to start server on #{@config.host}:#{@config.port}", @config.port, @config.host)
      rescue ex
        Logger.fatal("Server error", error: ex.message)
        raise ServerError.new("Server error: #{ex.message}")
      end
    end

    private def build_initial_site
      Logger.build_operation("Building initial site")
      @generator.build
      @last_build_time = Time.utc
      Logger.build_operation("Initial build complete")
    end

    private def configure_server_socket(server : HTTP::Server)
      # Note: HTTP::Server doesn't expose socket configuration directly
      # This method is a placeholder for future enhancements or custom server implementations
      # For now, we log the configuration options for debugging purposes
      Logger.debug("Socket configuration requested",
        reuse_address: @config.socket_reuse_address,
        keepalive: @config.socket_keepalive,
        timeout: @config.socket_timeout)
    rescue ex
      Logger.warn("Failed to configure socket options", error: ex.message)
    end

    private def handle_request(context : HTTP::Server::Context)
      start_time = Time.monotonic
      path = context.request.path
      method = context.request.method

      begin
        # Handle WebSocket upgrade for live reload
        if @live_reload.handle_websocket_upgrade(context)
          duration = Time.monotonic - start_time
          Logger.http_request(method, path, 101, duration) # 101 Switching Protocols
          return
        end

        # Legacy live reload endpoint (kept for backward compatibility)
        if path == "/__lapis_reload__"
          context.response.content_type = "text/plain"
          context.response.print "ok"
          duration = Time.monotonic - start_time
          Logger.http_request(method, path, 200, duration)
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

        duration = Time.monotonic - start_time
        Logger.http_request(method, path, context.response.status_code, duration)
      rescue ex
        duration = Time.monotonic - start_time
        Logger.error("Request handling error", method: method, path: path, error: ex.message, duration: duration.total_milliseconds.to_s)
        serve_500(context)
      end
    end

    private def serve_file(context : HTTP::Server::Context, file_path : String)
      context.response.content_type = mime_type(file_path)

      begin
        Logger.file_operation("serving", file_path)

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
        Logger.warn("File not found", file: file_path)
        serve_404(context)
      rescue ex : IO::Error
        Logger.error("IO error serving file", file: file_path, error: ex.message)
        serve_500(context)
      end
    end

    private def serve_404(context : HTTP::Server::Context)
      context.response.status_code = 404
      context.response.content_type = "text/html"
      context.response.print(not_found_page)
    end

    private def serve_500(context : HTTP::Server::Context)
      context.response.status_code = 500
      context.response.content_type = "text/html"
      context.response.print(internal_error_page)
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

    private def internal_error_page : String
      <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>500 - Internal Server Error</title>
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
        <h1>500</h1>
        <p>An internal server error occurred.</p>
        <p><a href="/">Go back to homepage</a></p>
      </body>
      </html>
      HTML
    end
  end
end
