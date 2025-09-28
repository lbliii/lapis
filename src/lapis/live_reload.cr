require "digest/sha1"
require "base64"
require "./logger"

module Lapis
  class LiveReload
    property config : Config
    property generator : Generator
    property file_watcher : FileWatcher
    property websocket_handler : WebSocketHandler
    property last_build_time : Time

    def initialize(@config : Config, @generator : Generator)
      @last_build_time = Time.utc
      @websocket_handler = WebSocketHandler.new(@config.live_reload_config.websocket_path)
      @file_watcher = FileWatcher.new(@config, ->handle_file_change(String))
    end

    def start
      @file_watcher.start_watching
    end

    def stop
      @file_watcher.stop_watching
    end

    def handle_websocket_upgrade(context : HTTP::Server::Context) : Bool
      if context.request.path == @websocket_handler.path
        begin
          # Check if this is a WebSocket upgrade request
          if context.request.headers["Upgrade"]? == "websocket"
            # Use HTTP::WebSocketHandler to properly handle the upgrade
            spawn handle_websocket_connection(context)
            return true
          end
        rescue ex
          Logger.error("Failed to upgrade to WebSocket", error: ex.message)
          return false
        end
      end
      false
    end

    private def handle_websocket_connection(context : HTTP::Server::Context)
      # Create WebSocket handler using the proper Crystal API
      websocket_handler = HTTP::WebSocketHandler.new do |socket|
        @websocket_handler.add_connection(socket)

        Logger.websocket_event("Connection established", path: context.request.path)

        # Set up message handlers
        socket.on_message do |message|
          Logger.websocket_event("Message received", message: message)
          # Handle incoming messages if needed
        end

        socket.on_close do |code, message|
          Logger.websocket_event("Connection closed", code: code.to_s, message: message)
          @websocket_handler.remove_connection(socket)
        end

        socket.on_ping do |message|
          Logger.websocket_event("Ping received")
          socket.pong(message)
        end
      end

      # Handle the WebSocket upgrade
      websocket_handler.call(context)
    rescue ex
      Logger.error("Error handling WebSocket connection", error: ex.message)
    end

    private def handle_file_change(file_path : String)
      Logger.debug("Handling file change", file_path: file_path)

      # Determine what needs to be rebuilt
      if should_rebuild_site?(file_path)
        rebuild_and_notify(file_path)
      elsif should_reload_assets?(file_path)
        notify_asset_change(file_path)
      end
    end

    private def should_rebuild_site?(file_path : String) : Bool
      ext = File.extname(file_path).downcase
      case ext
      when ".md", ".html", ".yml", ".yaml"
        true
      when ".css", ".js"
        # For CSS/JS in content directories, rebuild site
        # For CSS/JS in static directories, just reload assets
        !file_path.includes?("/static/") && !file_path.includes?("static/")
      else
        # Check if it's a config file
        file_path == "config.yml" || file_path == "config.yaml"
      end
    end

    private def should_reload_assets?(file_path : String) : Bool
      ext = File.extname(file_path).downcase
      case ext
      when ".css", ".js"
        file_path.includes?("/static/") || file_path.includes?("static/")
      else
        false
      end
    end

    private def rebuild_and_notify(file_path : String)
      Logger.build_operation("Rebuilding site", file_path: file_path)

      begin
        @generator.build
        @last_build_time = Time.utc
        Logger.build_operation("Site rebuilt successfully")

        # Notify clients to reload
        @websocket_handler.broadcast_reload(file_path)
      rescue ex
        Logger.error("Error rebuilding site", error: ex.message)
        # Still notify clients in case they need to refresh to see error pages
        @websocket_handler.broadcast_full_reload
      end
    end

    private def notify_asset_change(file_path : String)
      Logger.debug("Asset changed", file_path: file_path)

      ext = File.extname(file_path).downcase
      case ext
      when ".css"
        @websocket_handler.broadcast_css_reload([file_path])
      when ".js"
        @websocket_handler.broadcast_js_reload([file_path])
      else
        @websocket_handler.broadcast_reload(file_path)
      end
    end

    def connection_count : Int32
      @websocket_handler.connection_count
    end

    def has_connections? : Bool
      @websocket_handler.has_connections?
    end
  end
end
