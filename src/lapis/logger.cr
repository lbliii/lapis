require "log"

module Lapis
  # Structured logging system for Lapis
  class Logger
    @@initialized = false

    # Initialize the logging system
    def self.setup(config : Config? = nil)
      return if @@initialized

      # Simple console logging setup
      Log.setup do |c|
        c.bind "*", :info, Log::IOBackend.new(STDOUT)
      end

      @@initialized = true
      Log.info { "Lapis logging system initialized" }
    end

    # Determine appropriate log level
    private def self.determine_log_level(config : Config?) : Log::Severity
      if config && config.debug
        Log::Severity::Debug
      elsif ENV["LAPIS_LOG_LEVEL"]?
        case ENV["LAPIS_LOG_LEVEL"].downcase
        when "debug" then Log::Severity::Debug
        when "info" then Log::Severity::Info
        when "warn" then Log::Severity::Warn
        when "error" then Log::Severity::Error
        else Log::Severity::Info
        end
      else
        Log::Severity::Info
      end
    end

    # Convenience methods for different log levels
    def self.debug(message : String, **context)
      Log.debug { format_message(message, context) }
    end

    def self.info(message : String, **context)
      Log.info { format_message(message, context) }
    end

    def self.warn(message : String, **context)
      Log.warn { format_message(message, context) }
    end

    def self.error(message : String, **context)
      Log.error { format_message(message, context) }
    end

    def self.fatal(message : String, **context)
      Log.fatal { format_message(message, context) }
    end

    # Performance logging
    def self.time_operation(operation : String, **context, &block)
      start_time = Time.monotonic
      Log.debug { "Starting #{operation}" }
      
      result = yield
      
      duration = Time.monotonic - start_time
      Log.info { "Completed #{operation} in #{format_duration(duration)}" }
      
      result
    rescue ex
      duration = Time.monotonic - start_time
      Log.error { "Failed #{operation} after #{format_duration(duration)}: #{ex.message}" }
      raise ex
    end

    # File operation logging
    def self.file_operation(operation : String, file_path : String, **context)
      Log.debug { "File #{operation}: #{file_path}" }
    rescue ex
      Log.error { "File #{operation} failed for #{file_path}: #{ex.message}" }
      raise ex
    end

    # HTTP request logging
    def self.http_request(method : String, path : String, status : Int32, duration : Time::Span? = nil, **context)
      duration_str = duration ? " in #{format_duration(duration)}" : ""
      Log.info { "#{method} #{path} -> #{status}#{duration_str}" }
    end

    # Build operation logging
    def self.build_operation(operation : String, **context)
      Log.info { "Build: #{operation}" }
    end

    # WebSocket logging
    def self.websocket_event(event : String, **context)
      Log.debug { "WebSocket: #{event}" }
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
