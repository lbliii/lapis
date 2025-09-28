require "log"

module Lapis
  # Channel-based file change notification system
  class FileChangeChannel
    alias ChangeEvent = NamedTuple(
      path: String,
      event_type: String,
      timestamp: Time,
      file_size: Int64?,
      file_hash: String?
    )

    property change_channel : Channel(ChangeEvent)
    property shutdown_channel : Channel(Nil)
    property is_running : Bool = false

    def initialize(buffer_size : Int32 = 100)
      @change_channel = Channel(ChangeEvent).new(buffer_size)
      @shutdown_channel = Channel(Nil).new
    end

    # Send a file change event
    def send_change(path : String, event_type : String, file_size : Int64? = nil, file_hash : String? = nil)
      event = ChangeEvent.new(
        path: path,
        event_type: event_type,
        timestamp: Time.utc,
        file_size: file_size,
        file_hash: file_hash
      )
      
      begin
        @change_channel.send(event)
        Log.debug { "File change event sent: #{event_type} #{path}" }
      rescue Channel::ClosedError
        Log.warn { "Attempted to send change event to closed channel: #{path}" }
      end
    end

    # Receive file change events
    def receive_change : ChangeEvent?
      @change_channel.receive?
    end

    # Wait for shutdown signal
    def wait_for_shutdown
      @shutdown_channel.receive
    end

    # Signal shutdown
    def signal_shutdown
      @shutdown_channel.send(nil)
    end

    # Close the channel
    def close
      @change_channel.close
      @shutdown_channel.close
      @is_running = false
      Log.info { "File change channel closed" }
    end

    # Check if channel is closed
    def closed? : Bool
      @change_channel.closed?
    end
  end

  # Enhanced file watcher using channels
  class ChannelFileWatcher
    property config : Config
    property change_channel : FileChangeChannel
    property watching : Bool = false
    property file_timestamps : Hash(String, Time) = {} of String => Time
    property file_hashes : Hash(String, String) = {} of String => String

    def initialize(@config : Config)
      @change_channel = FileChangeChannel.new
    end

    def start_watching
      return if @watching

      @watching = true
      Log.info { "Starting channel-based file watcher" }
      
      spawn do
        watch_loop
      end
    end

    def stop_watching
      return unless @watching

      @watching = false
      @change_channel.signal_shutdown
      Log.info { "Stopping channel-based file watcher" }
    end

    # Get the change channel for external consumers
    def change_channel : FileChangeChannel
      @change_channel
    end

    private def watch_loop
      initialize_file_timestamps
      
      Log.info { "File watcher monitoring directories:" }
      config = @config.live_reload_config
      
      if config.watch_content && Dir.exists?(@config.content_dir)
        Log.info { "  - content: #{@config.content_dir}" }
      end
      if config.watch_layouts && Dir.exists?(@config.layouts_dir)
        Log.info { "  - layouts: #{@config.layouts_dir}" }
      end
      if config.watch_static && Dir.exists?(@config.static_dir)
        Log.info { "  - static: #{@config.static_dir}" }
      end

      loop do
        break unless @watching

        begin
          check_for_changes
          sleep 2.seconds
        rescue ex
          Log.error { "Error in file watcher: #{ex.message}" }
          sleep 5.seconds
        end
      end

      @change_channel.close
    end

    private def initialize_file_timestamps
      @file_timestamps.clear
      @file_hashes.clear

      config = @config.live_reload_config
      
      if config.watch_content && Dir.exists?(@config.content_dir)
        scan_directory(@config.content_dir, "content")
      end
      if config.watch_layouts && Dir.exists?(@config.layouts_dir)
        scan_directory(@config.layouts_dir, "layouts")
      end
      if config.watch_static && Dir.exists?(@config.static_dir)
        scan_directory(@config.static_dir, "static")
      end
    end

    private def scan_directory(dir : String, type : String)
      Dir.glob(File.join(dir, "**", "*")).each do |file_path|
        next unless File.file?(file_path)
        next if should_ignore_file?(file_path)

        begin
          @file_timestamps[file_path] = File.info(file_path).modification_time
          @file_hashes[file_path] = calculate_file_hash(file_path)
        rescue ex
          Log.warn { "Could not initialize timestamp for #{file_path}: #{ex.message}" }
        end
      end
    end

    private def check_for_changes
      config = @config.live_reload_config
      
      if config.watch_content && Dir.exists?(@config.content_dir)
        check_directory(@config.content_dir, "content")
      end
      if config.watch_layouts && Dir.exists?(@config.layouts_dir)
        check_directory(@config.layouts_dir, "layouts")
      end
      if config.watch_static && Dir.exists?(@config.static_dir)
        check_directory(@config.static_dir, "static")
      end
    end

    private def check_directory(dir : String, type : String)
      Dir.glob(File.join(dir, "**", "*")).each do |file_path|
        next unless File.file?(file_path)
        next if should_ignore_file?(file_path)

        begin
          current_time = File.info(file_path).modification_time
          current_hash = calculate_file_hash(file_path)
          
          if !@file_timestamps[file_path]? || @file_timestamps[file_path] != current_time
            # File changed
            event_type = @file_timestamps[file_path]? ? "modified" : "created"
            file_size = File.info(file_path).size
            
            @change_channel.send_change(file_path, event_type, file_size, current_hash)
            
            @file_timestamps[file_path] = current_time
            @file_hashes[file_path] = current_hash
          end
        rescue ex
          Log.warn { "Error checking file #{file_path}: #{ex.message}" }
        end
      end

      # Check for deleted files
      @file_timestamps.each do |file_path, _|
        unless File.exists?(file_path)
          @change_channel.send_change(file_path, "deleted")
          @file_timestamps.delete(file_path)
          @file_hashes.delete(file_path)
        end
      end
    end

    private def should_ignore_file?(file_path : String) : Bool
      config = @config.live_reload_config
      
      config.ignore_patterns.any? do |pattern|
        if pattern.includes?("*")
          File.match?(pattern, file_path)
        else
          file_path.includes?(pattern)
        end
      end
    end

    private def calculate_file_hash(file_path : String) : String
      digest = Digest::MD5.new
      File.open(file_path, "r") do |file|
        IO.copy(file, digest)
      end
      digest.hexdigest
    rescue ex
      Log.warn { "Could not calculate hash for #{file_path}: #{ex.message}" }
      ""
    end
  end
end
