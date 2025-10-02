require "log"
require "colorize"
require "./pretty_print_utils"

module Lapis
  # Custom cute log backend
  class CuteLogBackend < Log::Backend
    @@suppress_theme_init = false
    @@theme_init_count = 0

    def initialize
      # Force synchronous logging to avoid async/channel issues
      super(dispatcher: Log::DirectDispatcher)
    end

    def write(entry : Log::Entry)
      # Avoid timezone loading by using a simple time format
      # Override the entry's timestamp to use UTC instead of local time
      time_str = Time.utc.to_s("%H:%M:%S")
      message = entry.message.to_s

      # Suppress expected test errors in test mode
      if ENV["LAPIS_TEST_MODE"]? == "true"
        # Suppress expected YAML/JSON parsing errors from test files
        return if message.includes?("YAML parsing error") &&
                  (message.includes?("test_invalid.yml") ||
                  message.includes?("test_temp") ||
                  message.includes?("corrupted-theme") ||
                  message.includes?("corrupted-shard") ||
                  message.includes?("test_conversion_invalid.yml") ||
                  message.includes?("test_safe_invalid.yml") ||
                  message.includes?("test_safe_nil.yml") ||
                  message.includes?("test_file.yml") ||
                  message.includes?("test_safe_warning.yml") ||
                  message.includes?("empty-files-theme") ||
                  message.includes?("/var/folders/") ||
                  message.includes?("invalid: yaml: content: here"))

        # Suppress other expected test errors
        return if message.includes?("JSON parsing error") &&
                  (message.includes?("test_invalid.json") ||
                  message.includes?("test_temp") ||
                  message.includes?("test_conversion_invalid.json") ||
                  message.includes?("test_pretty_invalid.json") ||
                  message.includes?("test_file.json"))

        # Suppress expected type cast errors from test files
        return if message.includes?("Type-safe JSON parsing error") &&
                  (message.includes?("test_typed_invalid.json") ||
                  message.includes?("test_typed_cast_error.json") ||
                  message.includes?("test_typed_error.json"))

        # Suppress expected theme manager errors
        return if message.includes?("Unexpected error reading theme info") &&
                  message.includes?("test_temp")

        # Suppress expected parallel processor test errors
        return if message.includes?("Task failed") &&
                  (message.includes?("task_id=task1") ||
                  message.includes?("Simulated error"))

        # Suppress expected error logging test messages
        return if message.includes?("Test error message") ||
                  message.includes?("Test error [file=test_file.cr]")

        # Suppress expected build errors from tests
        return if message.includes?("Unexpected build error") &&
                  message.includes?("Unable to create directory: '/invalid'")

        # Suppress expected server errors from tests
        return if message.includes?("Server error") &&
                  message.includes?("Hostname lookup for localhost failed")
      end

      # Special handling for certain messages
      if message.includes?("Theme manager initialized")
        return if @@suppress_theme_init
        @@theme_init_count += 1
        if @@theme_init_count > 5
          @@suppress_theme_init = true
          puts "   📦 Theme manager ready (suppressing further messages)"
          return
        end
      end

      # Format with emojis
      case entry.severity
      when Log::Severity::Debug
        puts "   #{time_str} 🔍 #{message}"
      when Log::Severity::Info
        puts "   #{time_str} ℹ️  #{message}"
      when Log::Severity::Warn
        puts "   #{time_str} ⚠️  #{message}"
      when Log::Severity::Error
        puts "   #{time_str} ❌ #{message}"
      when Log::Severity::Fatal
        puts "   #{time_str} 💥 #{message}"
      else
        puts "   #{time_str} #{message}"
      end
    end
  end

  # Cute and clean logging system for Lapis
  class Logger
    @@initialized = false
    @@log_level = Log::Severity::Info
    @@suppress_theme_init = false
    @@theme_init_count = 0
    @@build_counter : Int32 = 0
    @@current_build_id : Int32? = nil

    # Initialize the logging system
    def self.setup(config : Config? = nil)
      return if @@initialized

      # Determine log level
      @@log_level =
        if config && config.debug
          Log::Severity::Debug
        elsif ENV.has_key?("LAPIS_LOG_LEVEL")
          case ENV.fetch("LAPIS_LOG_LEVEL").downcase
          when "debug" then Log::Severity::Debug
          when "info"  then Log::Severity::Info
          when "warn"  then Log::Severity::Warn
          when "error" then Log::Severity::Error
          else              Log::Severity::Info
          end
        else
          Log::Severity::Info
        end

      # Custom cute console logging setup
      Log.setup do |c|
        c.bind "*", @@log_level, CuteLogBackend.new
      end

      @@initialized = true
      # Don't use puts here to avoid recursion
    end

    def self.info(message : String, **context)
      # Temporarily disable complex logging to avoid infinite recursion
      # puts "#{Time.utc.to_s("%H:%M:%S")} ℹ️  #{message}"
    end

    def self.debug(message : String, **context)
      # Temporarily disabled
    end

    def self.warn(message : String, **context)
      # Temporarily disabled
    end

    def self.error(message : String, **context)
      # Temporarily disabled
    end

    def self.debug_object(message : String, obj, **context)
      Log.debug { "#{message} [#{obj.inspect}] #{format_context(context)}" }
    end

    def self.info_object(message : String, obj, **context)
      Log.info { "#{message} [#{obj.inspect}] #{format_context(context)}" }
    end

    def self.warn_object(message : String, obj, **context)
      Log.warn { "#{message} [#{obj.inspect}] #{format_context(context)}" }
    end

    # Pretty print objects with structured formatting
    def self.debug_pretty(message : String, obj, **context)
      if context.empty?
        Log.debug { "#{message}:" }
      else
        Log.debug { "#{message} #{format_context(context)}:" }
      end

      # Use PrettyPrint for structured output
      io = IO::Memory.new
      PrettyPrintUtils.format(obj, io, 80, 4) # 4-space indent for nested content
      io.to_s.each_line do |line|
        Log.debug { "    #{line}" } # Additional indent for pretty printed content
      end
    end

    def self.info_pretty(message : String, obj, **context)
      if context.empty?
        Log.info { "#{message}:" }
      else
        Log.info { "#{message} #{format_context(context)}:" }
      end

      # Use PrettyPrint for structured output
      io = IO::Memory.new
      PrettyPrintUtils.format(obj, io, 80, 4)
      io.to_s.each_line do |line|
        Log.info { "    #{line}" }
      end
    end

    # Pretty print configuration objects
    def self.debug_config(message : String, config : Config, **context)
      if context.empty?
        Log.debug { "#{message}:" }
      else
        Log.debug { "#{message} #{format_context(context)}:" }
      end

      io = IO::Memory.new
      PrettyPrintUtils.format_config(config, io, 80)
      io.to_s.each_line do |line|
        Log.debug { "    #{line}" }
      end
    end

    # Pretty print content objects
    def self.debug_content(message : String, content : Content, **context)
      if context.empty?
        Log.debug { "#{message}:" }
      else
        Log.debug { "#{message} #{format_context(context)}:" }
      end

      io = IO::Memory.new
      PrettyPrintUtils.format_content(content, io, 80)
      io.to_s.each_line do |line|
        Log.debug { "    #{line}" }
      end
    end

    # Pretty print error context
    def self.error_context(message : String, context : Hash, **additional_context)
      Log.error { "#{message}:" }

      io = IO::Memory.new
      PrettyPrintUtils.format_error_context(context, io, 80)
      io.to_s.each_line do |line|
        Log.error { "    #{line}" }
      end

      unless additional_context.empty?
        Log.error { "Additional context: #{format_context(additional_context)}" }
      end
    end

    # Pretty print data structures
    def self.debug_data(message : String, data : JSON::Any | YAML::Any, **context)
      if context.empty?
        Log.debug { "#{message}:" }
      else
        Log.debug { "#{message} #{format_context(context)}:" }
      end

      io = IO::Memory.new
      PrettyPrintUtils.format_data_structure(data, io, 80)
      io.to_s.each_line do |line|
        Log.debug { "    #{line}" }
      end
    end

    def self.fatal(message : String, **context)
      Log.fatal { format_message(message, context) }
    end

    # Performance logging
    def self.time_operation(operation : String, **context, &)
      start_time = Time.monotonic
      Log.debug { "Starting #{operation}" }

      begin
        result = yield

        duration = Time.monotonic - start_time
        Log.info { "Completed #{operation} in #{format_duration(duration)}" }

        result
      rescue ex
        duration = Time.monotonic - start_time
        Log.error { "Failed #{operation} after #{format_duration(duration)}: #{ex.message}" }
        raise ex
      end
    end

    # Path operation logging
    def self.path_operation(operation : String, path : String, **context)
      Log.debug { "Path #{operation}: #{path} #{format_context(context)}" }
    rescue ex
      Log.error { "Path #{operation} failed for #{path}: #{ex.message}" }
      raise ex
    end

    def self.path_error(operation : String, path : String, error : String, **context)
      Log.error { "Path #{operation} error for #{path}: #{error} #{format_context(context)}" }
    end

    # File operation logging
    def self.file_operation(operation : String, file_path : String, **context)
      Log.debug { "File #{operation}: #{file_path}" }
    rescue ex
      Log.error { "File #{operation} failed for #{file_path}: #{ex.message}" }
      raise ex
    end

    # HTTP request logging - cute version
    def self.http_request(method : String, path : String, status : Int32, duration : Time::Span? = nil, **context)
      duration_str = duration ? " in #{format_duration(duration)}" : ""
      time_str = Time.utc.to_s("%H:%M:%S")

      # Choose emoji based on status
      emoji = case status
              when 200..299 then "✅"
              when 300..399 then "↗️ "
              when 400..499 then "⚠️ "
              when 500..599 then "💥"
              else               "📡"
              end

      # Choose color based on status
      color = case status
              when 200..299 then :green
              when 300..399 then :cyan
              when 400..499 then :yellow
              when 500..599 then :red
              else               :white
              end

      puts "   #{time_str} #{emoji} #{method} #{path} -> #{status}#{duration_str}".colorize(color)
    end

    # Build operation logging - cute version
    def self.build_operation(operation : String, **context)
      # Respect log level - only show build operations in debug mode or when not in test mode
      return if @@log_level > Log::Severity::Debug && ENV["LAPIS_TEST_MODE"]? == "true"

      time_str = Time.utc.to_s("%H:%M:%S")

      # Generate unique build ID for tracking
      build_id = Logger.generate_build_id(operation)

      # Choose emoji based on operation
      emoji = case operation.downcase
              when .includes?("starting")   then "🚀"
              when .includes?("completed")  then "✨"
              when .includes?("loading")    then "📚"
              when .includes?("generating") then "⚡"
              when .includes?("processing") then "🔧"
              when .includes?("assets")     then "🎨"
              when .includes?("feeds")      then "📡"
              else                               "🔨"
              end

      # Add context information if available
      context_str = if context.empty?
                      ""
                    else
                      " [#{context.map { |k, v| "#{k}=#{v}" }.join(" ")}]"
                    end

      puts "   #{time_str} #{emoji} Build: #{operation} #{build_id}#{context_str}".colorize(:blue)
    end

    # WebSocket logging
    def self.websocket_event(event : String, **context)
      Log.debug { "WebSocket: #{event}" }
    end

    # Type casting error logging
    def self.type_cast_error(operation : String, source_type : String, target_type : String, value : String? = nil, **context)
      value_str = value ? " value=#{value}" : ""
      Log.error { "TypeCastError in #{operation}: #{source_type} -> #{target_type}#{value_str} #{format_context(context)}" }
    end

    def self.type_cast_warning(operation : String, source_type : String, target_type : String, fallback : String, **context)
      Log.warn { "TypeCastWarning in #{operation}: #{source_type} -> #{target_type}, using fallback: #{fallback} #{format_context(context)}" }
    end

    def self.type_cast_success(operation : String, source_type : String, target_type : String, **context)
      Log.debug { "TypeCastSuccess in #{operation}: #{source_type} -> #{target_type} #{format_context(context)}" }
    end

    # Test context logging - includes test information when available
    def self.test_error(message : String, test_name : String? = nil, **context)
      test_context = test_name ? "test=#{test_name}" : "test=unknown"
      if context.empty?
        Log.error { "#{message} [#{test_context}]" }
      else
        context_str = context.map { |k, v| "#{k}=#{v}" }.join(" ")
        Log.error { "#{message} [#{context_str}] [#{test_context}]" }
      end
    end

    # Format message with context
    private def self.format_message(message : String, context : NamedTuple) : String
      if context.empty?
        message
      else
        context_str = context.map { |k, v| "#{k}=#{v}" }.join(" ")
        "#{message} [#{context_str}]"
      end
    end

    # Format message with context and source location
    private def self.format_message_with_location(message : String, context : NamedTuple) : String
      # Get caller information (skip this method and the Logger.error call)
      call_stack = caller
      location_str = if call_stack.size > 2
                       # Skip the first two entries (this method and Logger.error)
                       caller_line = call_stack[2]?
                       if caller_line
                         match = caller_line.not_nil!.match(/([^\/]+\.cr):(\d+):/)
                         if match
                           file_name = match[1]
                           line_number = match[2]
                           "#{file_name}:#{line_number}"
                         else
                           "unknown"
                         end
                       else
                         "unknown"
                       end
                     else
                       "unknown"
                     end

      if context.empty?
        "#{message} [src=#{location_str}]"
      else
        context_str = context.map { |k, v| "#{k}=#{v}" }.join(" ")
        "#{message} [#{context_str}] [src=#{location_str}]"
      end
    end

    # Format context for object logging
    private def self.format_context(context : NamedTuple) : String
      if context.empty?
        ""
      else
        context_str = context.map { |k, v| "#{k}=#{v}" }.join(" ")
        "[#{context_str}]"
      end
    end

    # Format duration for logging
    private def self.format_duration(duration : Time::Span) : String
      if duration.total_milliseconds < 1000
        "#{duration.total_milliseconds.round(2)}ms"
      elsif duration.total_seconds < 60
        "#{duration.total_seconds.round(2)}s"
      else
        minutes = (duration.total_seconds / 60).floor
        seconds = duration.total_seconds % 60
        "#{minutes}m #{seconds.round(1)}s"
      end
    end

    # Generate unique build ID for tracking builds
    def self.generate_build_id(operation : String) : String
      # Use a simple counter-based approach
      @@build_counter ||= 0
      @@build_counter = @@build_counter.not_nil! + 1

      # For "Starting site build" operations, create a new build session
      if operation.downcase.includes?("starting")
        @@current_build_id = @@build_counter
      end

      # Use the current build ID, or fallback to counter if not in a build session
      build_id = @@current_build_id || @@build_counter

      # Format as a short identifier
      "<#{build_id}>"
    end
  end
end
