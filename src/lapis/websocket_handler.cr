require "json"

module Lapis
  class WebSocketHandler
    alias ReloadMessage = NamedTuple(
      type: String,
      files: Array(String)?,
      timestamp: String
    )

    property connections : Array(HTTP::WebSocket) = [] of HTTP::WebSocket
    property path : String

    def initialize(@path : String = "/__lapis_live_reload__")
    end

    def add_connection(socket : HTTP::WebSocket)
      @connections << socket
      puts "WebSocket client connected (#{@connections.size} total)"

      socket.on_close do |code, message|
        puts "WebSocket client disconnected: #{code} - #{message}"
        remove_connection(socket)
      end
    end

    def remove_connection(socket : HTTP::WebSocket)
      @connections.delete(socket)
      puts "WebSocket client disconnected (#{@connections.size} total)"
    end

    def broadcast_reload(file_path : String)
      return if @connections.empty?

      message = ReloadMessage.new(
        type: determine_reload_type(file_path),
        files: [file_path],
        timestamp: Time.utc.to_s
      )

      broadcast_message(message.to_json)
    end

    def broadcast_full_reload
      return if @connections.empty?

      message = ReloadMessage.new(
        type: "full_reload",
        files: nil,
        timestamp: Time.utc.to_s
      )

      broadcast_message(message.to_json)
    end

    def broadcast_css_reload(files : Array(String))
      return if @connections.empty?

      message = ReloadMessage.new(
        type: "css_reload",
        files: files,
        timestamp: Time.utc.to_s
      )

      broadcast_message(message.to_json)
    end

    def broadcast_js_reload(files : Array(String))
      return if @connections.empty?

      message = ReloadMessage.new(
        type: "js_reload",
        files: files,
        timestamp: Time.utc.to_s
      )

      broadcast_message(message.to_json)
    end

    private def determine_reload_type(file_path : String) : String
      case File.extname(file_path).downcase
      when ".css"
        "css_reload"
      when ".js"
        "js_reload"
      when ".html", ".md", ".yml", ".yaml"
        "full_reload"
      else
        "full_reload"
      end
    end

    private def broadcast_message(message : String)
      closed_connections = [] of HTTP::WebSocket

      @connections.each do |socket|
        begin
          socket.send(message)
        rescue ex
          puts "Failed to send message to WebSocket client: #{ex.message}"
          closed_connections << socket
        end
      end

      # Remove failed connections
      closed_connections.each do |socket|
        remove_connection(socket)
      end

      puts "Broadcasted reload message to #{@connections.size} clients"
    end

    def connection_count : Int32
      @connections.size
    end

    def has_connections? : Bool
      !@connections.empty?
    end
  end
end
