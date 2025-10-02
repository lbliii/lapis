require "time"
require "./function_registry"

module Lapis
  # Time and date functions leveraging Crystal's Time module
  module TimeFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:now, 0) do |args|
        Time.utc.to_s("%Y-%m-%d %H:%M:%S")
      end

      FunctionRegistry.register_function(:date, 1) do |args|
        format = args[0]? || "%Y-%m-%d"
        Time.utc.to_s(format)
      end

      FunctionRegistry.register_function(:time, 1) do |args|
        format = args[0]? || "%H:%M:%S"
        Time.utc.to_s(format)
      end

      FunctionRegistry.register_function(:datetime, 1) do |args|
        format = args[0]? || "%Y-%m-%d %H:%M:%S"
        Time.utc.to_s(format)
      end

      FunctionRegistry.register_function(:timestamp, 0) do |args|
        Time.utc.to_unix.to_s
      end

      FunctionRegistry.register_function(:rfc3339, 0) do |args|
        Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
      end

      FunctionRegistry.register_function(:iso8601, 0) do |args|
        Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
      end

      FunctionRegistry.register_function(:ago, 1) do |args|
        time_str = args[0]? || ""
        begin
          time = Time.parse(time_str, "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
          diff = Time.utc - time

          if diff.total_days >= 1
            "#{diff.total_days.to_i} days ago"
          elsif diff.total_hours >= 1
            "#{diff.total_hours.to_i} hours ago"
          elsif diff.total_minutes >= 1
            "#{diff.total_minutes.to_i} minutes ago"
          else
            "#{diff.total_seconds.to_i} seconds ago"
          end
        rescue
          "Invalid date"
        end
      end

      FunctionRegistry.register_function(:"time_ago", 1) do |args|
        time_str = args[0]? || ""
        begin
          time = Time.parse(time_str, "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
          diff = Time.utc - time

          if diff.total_days >= 365
            years = (diff.total_days / 365).to_i
            years == 1 ? "1 year ago" : "#{years} years ago"
          elsif diff.total_days >= 30
            months = (diff.total_days / 30).to_i
            months == 1 ? "1 month ago" : "#{months} months ago"
          elsif diff.total_days >= 1
            days = diff.total_days.to_i
            days == 1 ? "1 day ago" : "#{days} days ago"
          elsif diff.total_hours >= 1
            hours = diff.total_hours.to_i
            hours == 1 ? "1 hour ago" : "#{hours} hours ago"
          elsif diff.total_minutes >= 1
            minutes = diff.total_minutes.to_i
            minutes == 1 ? "1 minute ago" : "#{minutes} minutes ago"
          else
            "Just now"
          end
        rescue
          "Invalid date"
        end
      end
    end
  end
end
