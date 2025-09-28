require "log"
require "colorize"

module Lapis
  # Custom cute log backend
  class CuteLogBackend < Log::IOBackend
    @@suppress_theme_init = false
    @@theme_init_count = 0

    def initialize
      super(STDOUT)
    end

    def write(entry : Log::Entry)
      time_str = entry.timestamp.to_s("%H:%M:%S")
      message = entry.message.to_s

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

    # Initialize the logging system
    def self.setup(config : Config? = nil)
      return if @@initialized

      # Determine log level
      @@log_level =
        if config && config.debug
          Log::Severity::Debug
        elsif ENV["LAPIS_LOG_LEVEL"]?
          case ENV["LAPIS_LOG_LEVEL"].downcase
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
      puts "🐰 Lapis logging system initialized".colorize(:green)
    end

    def self.info(message : String, **context)
      Log.info { format_message(message, context) }
    end

    def self.debug(message : String, **context)
      Log.debug { format_message(message, context) }
    end

    def self.warn(message : String, **context)
      Log.warn { format_message(message, context) }
    end

    def self.error(message : String, **context)
      Log.error { format_message(message, context) }
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
      time_str = Time.utc.to_s("%H:%M:%S")

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

      puts "   #{time_str} #{emoji} Build: #{operation}".colorize(:blue)
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

    # Format message with context
    private def self.format_message(message : String, context : NamedTuple) : String
      if context.empty?
        message
      else
        context_str = context.map { |k, v| "#{k}=#{v}" }.join(" ")
        "#{message} [#{context_str}]"
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
  end
end
