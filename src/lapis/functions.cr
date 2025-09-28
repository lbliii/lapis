require "math"
require "time"
require "string"
require "array"
require "hash"

module Lapis
  class Functions
    # Function registry - comprehensive function system
    FUNCTIONS = {} of String => Proc(Array(String), String)

    # Register all function categories
    def self.setup
      register_string_functions
      register_array_functions
      register_math_functions
      register_time_functions
      register_hash_functions
      register_url_functions
      register_logic_functions
      register_type_functions
      register_markdown_functions
      register_text_functions
      register_file_functions
    end

    def self.call(name : String, args : Array(String)) : String
      if func = FUNCTIONS[name]?
        func.call(args)
      else
        ""
      end
    end

    def self.function_list : Array(String)
      FUNCTIONS.keys
    end

    def self.has_function?(name : String) : Bool
      FUNCTIONS.has_key?(name)
    end

    # STRING FUNCTIONS - Leveraging Crystal's String methods
    private def self.register_string_functions
      # Basic string manipulation using Crystal's String methods
      FUNCTIONS["upper"] = ->(args : Array(String)) : String {
        args[0]?.try(&.upcase) || ""
      }

      FUNCTIONS["lower"] = ->(args : Array(String)) : String {
        args[0]?.try(&.downcase) || ""
      }

      FUNCTIONS["title"] = ->(args : Array(String)) : String {
        args[0]?.try(&.split.map(&.capitalize).join(" ")) || ""
      }

      FUNCTIONS["trim"] = ->(args : Array(String)) : String {
        args[0]?.try(&.strip) || ""
      }

      FUNCTIONS["lstrip"] = ->(args : Array(String)) : String {
        args[0]?.try(&.lstrip) || ""
      }

      FUNCTIONS["rstrip"] = ->(args : Array(String)) : String {
        args[0]?.try(&.rstrip) || ""
      }

      FUNCTIONS["chomp"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        suffix = args[1]? || "\n"
        str.chomp(suffix)
      }

      FUNCTIONS["slugify"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      }

      FUNCTIONS["camelize"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.split(/[-_\s]+/).map(&.capitalize).join
      }

      FUNCTIONS["underscore"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.gsub(/([A-Z])/, "_\\1").downcase.gsub(/^_/, "")
      }

      FUNCTIONS["dasherize"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.gsub(/([A-Z])/, "-\\1").downcase.gsub(/^-/, "")
      }

      FUNCTIONS["pluralize"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        count = args[1]?.try(&.to_i?) || 1
        count == 1 ? str : "#{str}s"
      }

      FUNCTIONS["singularize"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.ends_with?("s") ? str.chomp("s") : str
      }

      FUNCTIONS["truncate"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        length = args[1]?.try(&.to_i?) || 50
        omission = args[2]? || "..."
        str.size > length ? "#{str[0, length - omission.size]}#{omission}" : str
      }

      FUNCTIONS["truncatewords"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        count = args[1]?.try(&.to_i?) || 15
        omission = args[2]? || "..."
        words = str.split
        words.size > count ? "#{words[0, count].join(" ")}#{omission}" : str
      }

      FUNCTIONS["strip_newlines"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.gsub(/\n+/, " ").strip
      }

      FUNCTIONS["newline_to_br"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.gsub(/\n/, "<br>")
      }

      FUNCTIONS["escape"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        HTML.escape(str)
      }

      FUNCTIONS["unescape"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        HTML.unescape(str)
      }
    end

    # ARRAY FUNCTIONS
    private def self.register_array_functions
      FUNCTIONS["len"] = ->(args : Array(String)) : String {
        args[0] ? args[0].size.to_s : "0"
      }
    end

    # MATH FUNCTIONS - Leveraging Crystal's Math module
    private def self.register_math_functions
      FUNCTIONS["add"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        (a + b).to_s
      }

      FUNCTIONS["subtract"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        (a - b).to_s
      }

      FUNCTIONS["multiply"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        (a * b).to_s
      }

      FUNCTIONS["divide"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 1.0
        b == 0.0 ? "0" : (a / b).to_s
      }

      FUNCTIONS["modulo"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_i?) || 0
        b = args[1]?.try(&.to_i?) || 1
        (a % b).to_s
      }

      FUNCTIONS["round"] = ->(args : Array(String)) : String {
        value = args[0]?.try(&.to_f?) || 0.0
        precision = args[1]?.try(&.to_i?) || 0
        value.round(precision).to_s
      }

      FUNCTIONS["ceil"] = ->(args : Array(String)) : String {
        value = args[0]?.try(&.to_f?) || 0.0
        value.ceil.to_s
      }

      FUNCTIONS["floor"] = ->(args : Array(String)) : String {
        value = args[0]?.try(&.to_f?) || 0.0
        value.floor.to_s
      }

      FUNCTIONS["abs"] = ->(args : Array(String)) : String {
        value = args[0]?.try(&.to_f?) || 0.0
        value.abs.to_s
      }

      FUNCTIONS["sqrt"] = ->(args : Array(String)) : String {
        value = args[0]?.try(&.to_f?) || 0.0
        Math.sqrt(value).to_s
      }

      FUNCTIONS["pow"] = ->(args : Array(String)) : String {
        base = args[0]?.try(&.to_f?) || 0.0
        exponent = args[1]?.try(&.to_f?) || 1.0
        (base ** exponent).to_s
      }

      FUNCTIONS["min"] = ->(args : Array(String)) : String {
        values = args.compact_map(&.to_f?)
        values.empty? ? "0" : values.min.to_s
      }

      FUNCTIONS["max"] = ->(args : Array(String)) : String {
        values = args.compact_map(&.to_f?)
        values.empty? ? "0" : values.max.to_s
      }

      FUNCTIONS["sum"] = ->(args : Array(String)) : String {
        values = args.compact_map(&.to_f?)
        values.sum.to_s
      }
    end

    # TIME FUNCTIONS - Leveraging Crystal's Time module
    private def self.register_time_functions
      FUNCTIONS["now"] = ->(args : Array(String)) : String {
        Time.utc.to_s("%Y-%m-%d %H:%M:%S")
      }

      FUNCTIONS["date"] = ->(args : Array(String)) : String {
        format = args[0]? || "%Y-%m-%d"
        Time.utc.to_s(format)
      }

      FUNCTIONS["time"] = ->(args : Array(String)) : String {
        format = args[0]? || "%H:%M:%S"
        Time.utc.to_s(format)
      }

      FUNCTIONS["datetime"] = ->(args : Array(String)) : String {
        format = args[0]? || "%Y-%m-%d %H:%M:%S"
        Time.utc.to_s(format)
      }

      FUNCTIONS["timestamp"] = ->(args : Array(String)) : String {
        Time.utc.to_unix.to_s
      }

      FUNCTIONS["rfc3339"] = ->(args : Array(String)) : String {
        Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
      }

      FUNCTIONS["iso8601"] = ->(args : Array(String)) : String {
        Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
      }

      FUNCTIONS["ago"] = ->(args : Array(String)) : String {
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
      }

      FUNCTIONS["time_ago"] = ->(args : Array(String)) : String {
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
      }
    end

    # HASH FUNCTIONS - Leveraging Crystal's Hash methods
    private def self.register_hash_functions
      FUNCTIONS["has_key"] = ->(args : Array(String)) : String {
        # This would need context from the template processor
        "false" # Placeholder
      }

      FUNCTIONS["keys"] = ->(args : Array(String)) : String {
        # This would need context from the template processor
        "" # Placeholder
      }

      FUNCTIONS["values"] = ->(args : Array(String)) : String {
        # This would need context from the template processor
        "" # Placeholder
      }
    end

    # URL FUNCTIONS - Enhanced URL handling
    private def self.register_url_functions
      FUNCTIONS["urlize"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      }

      FUNCTIONS["relative_url"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        base = args[1]? || ""
        url.starts_with?("http") ? url : "#{base.chomp("/")}/#{url.lstrip("/")}"
      }

      FUNCTIONS["absolute_url"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        base = args[1]? || ""
        url.starts_with?("http") ? url : "#{base.chomp("/")}/#{url.lstrip("/")}"
      }

      FUNCTIONS["url_encode"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        URI.encode_path(str)
      }

      FUNCTIONS["url_decode"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        URI.decode(str)
      }
    end

    # LOGIC FUNCTIONS - Enhanced logical operations
    private def self.register_logic_functions
      FUNCTIONS["eq"] = ->(args : Array(String)) : String {
        args[0] == args[1] ? "true" : "false"
      }

      FUNCTIONS["ne"] = ->(args : Array(String)) : String {
        args[0] != args[1] ? "true" : "false"
      }

      FUNCTIONS["gt"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a > b ? "true" : "false"
      }

      FUNCTIONS["lt"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a < b ? "true" : "false"
      }

      FUNCTIONS["gte"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a >= b ? "true" : "false"
      }

      FUNCTIONS["lte"] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a <= b ? "true" : "false"
      }

      FUNCTIONS["and"] = ->(args : Array(String)) : String {
        args.all? { |arg| arg == "true" || arg == "1" || arg != "" } ? "true" : "false"
      }

      FUNCTIONS["or"] = ->(args : Array(String)) : String {
        args.any? { |arg| arg == "true" || arg == "1" || arg != "" } ? "true" : "false"
      }

      FUNCTIONS["not"] = ->(args : Array(String)) : String {
        arg = args[0]? || ""
        (arg == "true" || arg == "1" || arg != "") ? "false" : "true"
      }

      FUNCTIONS["contains"] = ->(args : Array(String)) : String {
        haystack = args[0]? || ""
        needle = args[1]? || ""
        haystack.includes?(needle) ? "true" : "false"
      }

      FUNCTIONS["starts_with"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        prefix = args[1]? || ""
        str.starts_with?(prefix) ? "true" : "false"
      }

      FUNCTIONS["ends_with"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        suffix = args[1]? || ""
        str.ends_with?(suffix) ? "true" : "false"
      }
    end

    # TYPE FUNCTIONS - Enhanced type handling
    private def self.register_type_functions
      FUNCTIONS["string"] = ->(args : Array(String)) : String {
        args[0] || ""
      }

      FUNCTIONS["int"] = ->(args : Array(String)) : String {
        value = args[0]?.try(&.to_i?) || 0
        value.to_s
      }

      FUNCTIONS["float"] = ->(args : Array(String)) : String {
        value = args[0]?.try(&.to_f?) || 0.0
        value.to_s
      }

      FUNCTIONS["bool"] = ->(args : Array(String)) : String {
        arg = args[0]? || ""
        (arg == "true" || arg == "1" || arg != "") ? "true" : "false"
      }

      FUNCTIONS["array"] = ->(args : Array(String)) : String {
        args.join(",")
      }

      FUNCTIONS["size"] = ->(args : Array(String)) : String {
        args[0]?.try(&.size).to_s || "0"
      }

      FUNCTIONS["empty"] = ->(args : Array(String)) : String {
        arg = args[0]? || ""
        arg.empty? ? "true" : "false"
      }

      FUNCTIONS["blank"] = ->(args : Array(String)) : String {
        arg = args[0]? || ""
        arg.strip.empty? ? "true" : "false"
      }
    end

    # MARKDOWN FUNCTIONS - Markdown processing
    private def self.register_markdown_functions
      FUNCTIONS["markdownify"] = ->(args : Array(String)) : String {
        markdown = args[0]? || ""
        begin
          # This would use the Markd library for processing
          markdown # Placeholder - would need Markd integration
        rescue
          markdown
        end
      }

      FUNCTIONS["strip_html"] = ->(args : Array(String)) : String {
        html = args[0]? || ""
        html.gsub(/<[^>]*>/, "")
      }

      FUNCTIONS["escape_html"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        HTML.escape(str)
      }

      FUNCTIONS["unescape_html"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        HTML.unescape(str)
      }
    end

    # TEXT FUNCTIONS - Advanced text processing
    private def self.register_text_functions
      FUNCTIONS["word_count"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        text.split.size.to_s
      }

      FUNCTIONS["reading_time"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        words_per_minute = args[1]?.try(&.to_i?) || 200
        minutes = (text.split.size.to_f / words_per_minute).ceil
        minutes == 1 ? "1 min read" : "#{minutes} min read"
      }

      FUNCTIONS["first"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        count = args[1]?.try(&.to_i?) || 1
        text.split.first(count).join(" ")
      }

      FUNCTIONS["last"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        count = args[1]?.try(&.to_i?) || 1
        text.split.last(count).join(" ")
      }

      FUNCTIONS["replace"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        search = args[1]? || ""
        replace = args[2]? || ""
        text.gsub(search, replace)
      }

      FUNCTIONS["remove"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        search = args[1]? || ""
        text.gsub(search, "")
      }
    end

    # FILE FUNCTIONS - File system operations
    private def self.register_file_functions
      FUNCTIONS["file_exists"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        File.exists?(file_path) ? "true" : "false"
      }

      FUNCTIONS["file_size"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        begin
          File.size(file_path).to_s
        rescue
          "0"
        end
      }

      FUNCTIONS["file_extension"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        File.extname(file_path)
      }

      FUNCTIONS["file_basename"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        File.basename(file_path)
      }

      FUNCTIONS["file_dirname"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        File.dirname(file_path)
      }
    end
  end
end
