module Lapis
  class FileWatcher
    alias ChangeCallback = Proc(String, Nil)

    property config : Config
    property change_callback : ChangeCallback
    property watching : Bool = false
    property debounce_timer : Time?
    property file_timestamps : Hash(String, Time) = {} of String => Time

    def initialize(@config : Config, @change_callback : ChangeCallback)
    end

    def start_watching
      return if @watching

      @watching = true
      puts "File watcher started (efficient polling mode)"

      spawn do
        watch_loop
      end
    end

    def stop_watching
      return unless @watching

      @watching = false
      puts "File watcher stopped"
    end

    private def watch_loop
      # Initialize file timestamps
      initialize_file_timestamps

      puts "Watching directories:"
      config = @config.live_reload_config

      if config.watch_content && Dir.exists?(@config.content_dir)
        puts "  - content: #{@config.content_dir}"
      end
      if config.watch_layouts && Dir.exists?(@config.layouts_dir)
        puts "  - layouts: #{@config.layouts_dir}"
      end
      if config.watch_static && Dir.exists?(@config.static_dir)
        puts "  - static: #{@config.static_dir}"
      end

      loop do
        break unless @watching

        begin
          check_for_changes
          sleep 2.seconds # Much more efficient than 1 second polling
        rescue ex
          puts "Error in file watcher: #{ex.message}"
          sleep 5.seconds
        end
      end
    end

    private def initialize_file_timestamps
      @file_timestamps.clear
      config = @config.live_reload_config

      # Scan all relevant files and record their modification times
      scan_directory(@config.content_dir, "*.md") if config.watch_content
      scan_directory(@config.layouts_dir, "*") if config.watch_layouts
      scan_directory(@config.static_dir, "*") if config.watch_static

      # Scan theme directories
      if config.watch_layouts
        theme_layouts_dir = File.join(@config.theme_dir, "layouts")
        scan_directory(theme_layouts_dir, "*") if Dir.exists?(theme_layouts_dir)
      end

      if config.watch_static
        theme_static_dir = File.join(@config.theme_dir, "static")
        scan_directory(theme_static_dir, "*") if Dir.exists?(theme_static_dir)
      end

      # Watch config file
      if config.watch_config
        config_file = "config.yml"
        if File.exists?(config_file)
          @file_timestamps[config_file] = File.info(config_file).modification_time
        end
      end
    end

    private def scan_directory(dir_path : String, pattern : String)
      return unless Dir.exists?(dir_path)

      Dir.glob(File.join(dir_path, "**", pattern)).each do |file_path|
        if File.file?(file_path) && should_reload_for_file?(File.basename(file_path))
          @file_timestamps[file_path] = File.info(file_path).modification_time
        end
      end
    end

    private def check_for_changes
      changes_detected = [] of String
      config = @config.live_reload_config

      # Check content files
      if config.watch_content
        changes_detected.concat(check_directory(@config.content_dir, "*.md"))
      end

      # Check layout files
      if config.watch_layouts
        changes_detected.concat(check_directory(@config.layouts_dir, "*"))
        theme_layouts_dir = File.join(@config.theme_dir, "layouts")
        changes_detected.concat(check_directory(theme_layouts_dir, "*")) if Dir.exists?(theme_layouts_dir)
      end

      # Check static files
      if config.watch_static
        changes_detected.concat(check_directory(@config.static_dir, "*"))
        theme_static_dir = File.join(@config.theme_dir, "static")
        changes_detected.concat(check_directory(theme_static_dir, "*")) if Dir.exists?(theme_static_dir)
      end

      # Check config file
      if config.watch_config
        config_file = "config.yml"
        if File.exists?(config_file)
          current_time = File.info(config_file).modification_time
          if @file_timestamps[config_file]? != current_time
            @file_timestamps[config_file] = current_time
            changes_detected << config_file
          end
        end
      end

      # Process changes
      changes_detected.each do |file_path|
        handle_file_change(file_path)
      end
    end

    private def check_directory(dir_path : String, pattern : String) : Array(String)
      changes = [] of String
      return changes unless Dir.exists?(dir_path)

      Dir.glob(File.join(dir_path, "**", pattern)).each do |file_path|
        if File.file?(file_path) && should_reload_for_file?(File.basename(file_path))
          current_time = File.info(file_path).modification_time
          if @file_timestamps[file_path]? != current_time
            @file_timestamps[file_path] = current_time
            changes << file_path
          end
        end
      end

      changes
    end

    private def handle_file_change(file_path : String)
      # Debounce rapid changes using config setting
      debounce_ms = @config.live_reload_config.debounce_ms
      now = Time.utc
      if @debounce_timer && @debounce_timer.try { |timer| (now - timer).total_milliseconds < debounce_ms } || false
        return
      end
      @debounce_timer = now

      puts "File changed: #{File.basename(file_path)}"
      @change_callback.call(file_path)
    end

    private def should_reload_for_file?(filename : String) : Bool
      return false if filename.empty?

      # Check ignore patterns
      @config.live_reload_config.ignore_patterns.each do |pattern|
        if filename.includes?(pattern) || File.match?(pattern, filename)
          return false
        end
      end

      # Only reload for relevant file types
      case File.extname(filename).downcase
      when ".md", ".html", ".css", ".js", ".yml", ".yaml"
        true
      else
        # Check if it's a config file
        filename == "config.yml" || filename == "config.yaml"
      end
    end
  end
end
