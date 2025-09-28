require "math"
require "time"
require "string"
require "array"
require "hash"
require "uri"
require "html"
require "json"

module Lapis
  class Functions
    # Function registry - comprehensive function system using symbols for performance
    FUNCTIONS = {} of Symbol => Proc(Array(String), String)

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
      # Convert string to symbol for lookup (only works for compile-time known symbols)
      symbol_name = case name
                    when "upper"                 then :upper
                    when "lower"                 then :lower
                    when "title"                 then :title
                    when "trim"                  then :trim
                    when "lstrip"                then :lstrip
                    when "rstrip"                then :rstrip
                    when "chomp"                 then :chomp
                    when "slugify"               then :slugify
                    when "camelize"              then :camelize
                    when "underscore"            then :underscore
                    when "dasherize"             then :dasherize
                    when "pluralize"             then :pluralize
                    when "singularize"           then :singularize
                    when "truncate"              then :truncate
                    when "truncatewords"         then :"truncatewords"
                    when "strip_newlines"        then :"strip_newlines"
                    when "newline_to_br"         then :"newline_to_br"
                    when "escape"                then :escape
                    when "unescape"              then :unescape
                    when "len"                   then :len
                    when "add"                   then :add
                    when "subtract"              then :subtract
                    when "multiply"              then :multiply
                    when "divide"                then :divide
                    when "modulo"                then :modulo
                    when "round"                 then :round
                    when "ceil"                  then :ceil
                    when "floor"                 then :floor
                    when "abs"                   then :abs
                    when "sqrt"                  then :sqrt
                    when "pow"                   then :pow
                    when "min"                   then :min
                    when "max"                   then :max
                    when "sum"                   then :sum
                    when "now"                   then :now
                    when "date"                  then :date
                    when "time"                  then :time
                    when "datetime"              then :datetime
                    when "timestamp"             then :timestamp
                    when "rfc3339"               then :rfc3339
                    when "iso8601"               then :iso8601
                    when "ago"                   then :ago
                    when "time_ago"              then :"time_ago"
                    when "has_key"               then :"has_key"
                    when "keys"                  then :keys
                    when "values"                then :values
                    when "urlize"                then :urlize
                    when "relative_url"          then :"relative_url"
                    when "absolute_url"          then :"absolute_url"
                    when "url_encode"            then :"url_encode"
                    when "url_decode"            then :"url_decode"
                    when "url_normalize"         then :"url_normalize"
                    when "url_scheme"            then :"url_scheme"
                    when "url_host"              then :"url_host"
                    when "url_port"              then :"url_port"
                    when "url_path"              then :"url_path"
                    when "url_query"             then :"url_query"
                    when "url_fragment"          then :"url_fragment"
                    when "is_absolute_url"       then :"is_absolute_url"
                    when "is_valid_url"          then :"is_valid_url"
                    when "url_join"              then :"url_join"
                    when "url_components"        then :"url_components"
                    when "query_params"          then :"query_params"
                    when "update_query_param"    then :"update_query_param"
                    when "eq"                    then :eq
                    when "ne"                    then :ne
                    when "gt"                    then :gt
                    when "lt"                    then :lt
                    when "gte"                   then :gte
                    when "lte"                   then :lte
                    when "and"                   then :and
                    when "or"                    then :or
                    when "not"                   then :not
                    when "contains"              then :contains
                    when "starts_with"           then :"starts_with"
                    when "ends_with"             then :"ends_with"
                    when "string"                then :string
                    when "int"                   then :int
                    when "float"                 then :float
                    when "bool"                  then :bool
                    when "array"                 then :array
                    when "size"                  then :size
                    when "empty"                 then :empty
                    when "blank"                 then :blank
                    when "markdownify"           then :markdownify
                    when "strip_html"            then :"strip_html"
                    when "escape_html"           then :"escape_html"
                    when "unescape_html"         then :"unescape_html"
                    when "word_count"            then :"word_count"
                    when "reading_time"          then :"reading_time"
                    when "first"                 then :first
                    when "last"                  then :last
                    when "replace"               then :replace
                    when "remove"                then :remove
                    when "file_exists"           then :"file_exists"
                    when "file_size"             then :"file_size"
                    when "file_extension"        then :"file_extension"
                    when "file_extname"          then :"file_extname"
                    when "file_basename"         then :"file_basename"
                    when "file_dirname"          then :"file_dirname"
                    when "char_count"            then :"char_count"
                    when "char_count_alpha"      then :"char_count_alpha"
                    when "char_count_digit"      then :"char_count_digit"
                    when "char_count_upper"      then :"char_count_upper"
                    when "char_count_lower"      then :"char_count_lower"
                    when "char_count_whitespace" then :"char_count_whitespace"
                    when "extract_digits"        then :"extract_digits"
                    when "extract_letters"       then :"extract_letters"
                    when "is_numeric"            then :"is_numeric"
                    when "is_alpha"              then :"is_alpha"
                    when "is_alphanumeric"       then :"is_alphanumeric"
                    when "starts_with_upper"     then :"starts_with_upper"
                    else                              return ""
                    end

      if func = FUNCTIONS[symbol_name]?
        func.call(args)
      else
        ""
      end
    end

    def self.function_list : Array(String)
      FUNCTIONS.keys.map(&.to_s)
    end

    def self.has_function?(name : String) : Bool
      # Convert string to symbol for lookup (only works for compile-time known symbols)
      symbol_name = case name
                    when "upper"                 then :upper
                    when "lower"                 then :lower
                    when "title"                 then :title
                    when "trim"                  then :trim
                    when "lstrip"                then :lstrip
                    when "rstrip"                then :rstrip
                    when "chomp"                 then :chomp
                    when "slugify"               then :slugify
                    when "camelize"              then :camelize
                    when "underscore"            then :underscore
                    when "dasherize"             then :dasherize
                    when "pluralize"             then :pluralize
                    when "singularize"           then :singularize
                    when "truncate"              then :truncate
                    when "truncatewords"         then :"truncatewords"
                    when "strip_newlines"        then :"strip_newlines"
                    when "newline_to_br"         then :"newline_to_br"
                    when "escape"                then :escape
                    when "unescape"              then :unescape
                    when "len"                   then :len
                    when "add"                   then :add
                    when "subtract"              then :subtract
                    when "multiply"              then :multiply
                    when "divide"                then :divide
                    when "modulo"                then :modulo
                    when "round"                 then :round
                    when "ceil"                  then :ceil
                    when "floor"                 then :floor
                    when "abs"                   then :abs
                    when "sqrt"                  then :sqrt
                    when "pow"                   then :pow
                    when "min"                   then :min
                    when "max"                   then :max
                    when "sum"                   then :sum
                    when "now"                   then :now
                    when "date"                  then :date
                    when "time"                  then :time
                    when "datetime"              then :datetime
                    when "timestamp"             then :timestamp
                    when "rfc3339"               then :rfc3339
                    when "iso8601"               then :iso8601
                    when "ago"                   then :ago
                    when "time_ago"              then :"time_ago"
                    when "has_key"               then :"has_key"
                    when "keys"                  then :keys
                    when "values"                then :values
                    when "urlize"                then :urlize
                    when "relative_url"          then :"relative_url"
                    when "absolute_url"          then :"absolute_url"
                    when "url_encode"            then :"url_encode"
                    when "url_decode"            then :"url_decode"
                    when "url_normalize"         then :"url_normalize"
                    when "url_scheme"            then :"url_scheme"
                    when "url_host"              then :"url_host"
                    when "url_port"              then :"url_port"
                    when "url_path"              then :"url_path"
                    when "url_query"             then :"url_query"
                    when "url_fragment"          then :"url_fragment"
                    when "is_absolute_url"       then :"is_absolute_url"
                    when "is_valid_url"          then :"is_valid_url"
                    when "url_join"              then :"url_join"
                    when "url_components"        then :"url_components"
                    when "query_params"          then :"query_params"
                    when "update_query_param"    then :"update_query_param"
                    when "eq"                    then :eq
                    when "ne"                    then :ne
                    when "gt"                    then :gt
                    when "lt"                    then :lt
                    when "gte"                   then :gte
                    when "lte"                   then :lte
                    when "and"                   then :and
                    when "or"                    then :or
                    when "not"                   then :not
                    when "contains"              then :contains
                    when "starts_with"           then :"starts_with"
                    when "ends_with"             then :"ends_with"
                    when "string"                then :string
                    when "int"                   then :int
                    when "float"                 then :float
                    when "bool"                  then :bool
                    when "array"                 then :array
                    when "size"                  then :size
                    when "empty"                 then :empty
                    when "blank"                 then :blank
                    when "markdownify"           then :markdownify
                    when "strip_html"            then :"strip_html"
                    when "escape_html"           then :"escape_html"
                    when "unescape_html"         then :"unescape_html"
                    when "word_count"            then :"word_count"
                    when "reading_time"          then :"reading_time"
                    when "first"                 then :first
                    when "last"                  then :last
                    when "replace"               then :replace
                    when "remove"                then :remove
                    when "file_exists"           then :"file_exists"
                    when "file_size"             then :"file_size"
                    when "file_extension"        then :"file_extension"
                    when "file_extname"          then :"file_extname"
                    when "file_basename"         then :"file_basename"
                    when "file_dirname"          then :"file_dirname"
                    when "char_count"            then :"char_count"
                    when "char_count_alpha"      then :"char_count_alpha"
                    when "char_count_digit"      then :"char_count_digit"
                    when "char_count_upper"      then :"char_count_upper"
                    when "char_count_lower"      then :"char_count_lower"
                    when "char_count_whitespace" then :"char_count_whitespace"
                    when "extract_digits"        then :"extract_digits"
                    when "extract_letters"       then :"extract_letters"
                    when "is_numeric"            then :"is_numeric"
                    when "is_alpha"              then :"is_alpha"
                    when "is_alphanumeric"       then :"is_alphanumeric"
                    when "starts_with_upper"     then :"starts_with_upper"
                    else                              return false
                    end
      FUNCTIONS.has_key?(symbol_name)
    end

    # STRING FUNCTIONS - Leveraging Crystal's String methods
    private def self.register_string_functions
      # Basic string manipulation using Crystal's String methods
      FUNCTIONS[:upper] = ->(args : Array(String)) : String {
        args[0]?.try(&.upcase) || ""
      }

      FUNCTIONS[:lower] = ->(args : Array(String)) : String {
        args[0]?.try(&.downcase) || ""
      }

      FUNCTIONS[:title] = ->(args : Array(String)) : String {
        args[0]?.try(&.split.map(&.capitalize).join(" ")) || ""
      }

      FUNCTIONS[:trim] = ->(args : Array(String)) : String {
        args[0]?.try(&.strip) || ""
      }

      FUNCTIONS[:lstrip] = ->(args : Array(String)) : String {
        args[0]?.try(&.lstrip) || ""
      }

      FUNCTIONS[:rstrip] = ->(args : Array(String)) : String {
        args[0]?.try(&.rstrip) || ""
      }

      FUNCTIONS[:chomp] = ->(args : Array(String)) : String {
        str = args[0] || ""
        suffix = args[1]? || "\n"
        str.chomp(suffix)
      }

      FUNCTIONS[:slugify] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      }

      FUNCTIONS[:camelize] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.split(/[-_\s]+/).map(&.capitalize).join
      }

      FUNCTIONS[:underscore] = ->(args : Array(String)) : String {
        str = args[0] || ""
        # Use Char API for more precise character processing
        result = [] of Char
        chars = str.chars

        chars.each_with_index do |char, index|
          if char.uppercase? && index > 0
            result << '_'
          end
          result << char.downcase
        end

        result.join
      }

      FUNCTIONS[:dasherize] = ->(args : Array(String)) : String {
        str = args[0] || ""
        # Use Char API for more precise character processing
        result = [] of Char
        chars = str.chars

        chars.each_with_index do |char, index|
          if char.uppercase? && index > 0
            result << '-'
          end
          result << char.downcase
        end

        result.join
      }

      FUNCTIONS[:pluralize] = ->(args : Array(String)) : String {
        raise ArgumentError.new("pluralize requires at least 1 argument") if args.empty?
        str = args[0]
        count = args[1]?.try(&.to_i?) || 1
        count == 1 ? str : "#{str}s"
      }

      FUNCTIONS[:singularize] = ->(args : Array(String)) : String {
        raise ArgumentError.new("singularize requires exactly 1 argument") if args.size != 1
        str = args[0]
        str.ends_with?("s") ? str.chomp("s") : str
      }

      FUNCTIONS[:truncate] = ->(args : Array(String)) : String {
        raise ArgumentError.new("truncate requires at least 1 argument") if args.empty?
        str = args[0]
        length = args[1]?.try(&.to_i?) || 50
        raise ArgumentError.new("truncate length must be positive") if length < 0
        omission = args[2]? || "..."
        str.size > length ? "#{str[0, length - omission.size]}#{omission}" : str
      }

      FUNCTIONS[:"truncatewords"] = ->(args : Array(String)) : String {
        raise ArgumentError.new("truncatewords requires at least 1 argument") if args.empty?
        str = args[0]
        count = args[1]?.try(&.to_i?) || 15
        raise ArgumentError.new("truncatewords count must be positive") if count < 0
        omission = args[2]? || "..."
        words = str.split
        words.size > count ? "#{words[0, count].join(" ")}#{omission}" : str
      }

      FUNCTIONS[:"strip_newlines"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.gsub(/\n+/, " ").strip
      }

      FUNCTIONS[:"newline_to_br"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.gsub(/\n/, "<br>")
      }

      FUNCTIONS[:escape] = ->(args : Array(String)) : String {
        str = args[0] || ""
        HTML.escape(str)
      }

      FUNCTIONS[:unescape] = ->(args : Array(String)) : String {
        str = args[0] || ""
        HTML.unescape(str)
      }

      # Character-based utility functions using Char API
      FUNCTIONS[:"char_count"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.size.to_s
      }

      FUNCTIONS[:"char_count_alpha"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.chars.count(&.letter?).to_s
      }

      FUNCTIONS[:"char_count_digit"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.chars.count(&.number?).to_s
      }

      FUNCTIONS[:"char_count_upper"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.chars.count(&.uppercase?).to_s
      }

      FUNCTIONS[:"char_count_lower"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.chars.count(&.lowercase?).to_s
      }

      FUNCTIONS[:"char_count_whitespace"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.chars.count(&.whitespace?).to_s
      }

      FUNCTIONS[:"extract_digits"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.chars.select(&.number?).join
      }

      FUNCTIONS[:"extract_letters"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.chars.select(&.letter?).join
      }

      FUNCTIONS[:"is_numeric"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        (str.empty? ? false : str.chars.all?(&.number?)).to_s
      }

      FUNCTIONS[:"is_alpha"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        (str.empty? ? false : str.chars.all?(&.letter?)).to_s
      }

      FUNCTIONS[:"is_alphanumeric"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        (str.empty? ? false : str.chars.all? { |char| char.letter? || char.number? }).to_s
      }

      FUNCTIONS[:"starts_with_upper"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        (str.empty? ? false : str.chars[0].uppercase?).to_s
      }
    end

    # ARRAY FUNCTIONS
    private def self.register_array_functions
      FUNCTIONS[:len] = ->(args : Array(String)) : String {
        args[0] ? args[0].size.to_s : "0"
      }
    end

    # MATH FUNCTIONS - Leveraging Crystal's Math module
    private def self.register_math_functions
      FUNCTIONS[:add] = ->(args : Array(String)) : String {
        raise ArgumentError.new("add requires exactly 2 arguments") if args.size != 2
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("add arguments must be numeric") if !a || !b
        (a + b).to_s
      }

      FUNCTIONS[:subtract] = ->(args : Array(String)) : String {
        raise ArgumentError.new("subtract requires exactly 2 arguments") if args.size != 2
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("subtract arguments must be numeric") if !a || !b
        (a - b).to_s
      }

      FUNCTIONS[:multiply] = ->(args : Array(String)) : String {
        raise ArgumentError.new("multiply requires exactly 2 arguments") if args.size != 2
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("multiply arguments must be numeric") if !a || !b
        (a * b).to_s
      }

      FUNCTIONS[:divide] = ->(args : Array(String)) : String {
        raise ArgumentError.new("divide requires exactly 2 arguments") if args.size != 2
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("divide arguments must be numeric") if !a || !b
        raise ArgumentError.new("divide by zero") if b == 0.0
        (a / b).to_s
      }

      FUNCTIONS[:modulo] = ->(args : Array(String)) : String {
        raise ArgumentError.new("modulo requires exactly 2 arguments") if args.size != 2
        a = args[0].to_i?
        b = args[1].to_i?
        raise ArgumentError.new("modulo arguments must be integers") if !a || !b
        raise ArgumentError.new("modulo by zero") if b == 0
        (a % b).to_s
      }

      FUNCTIONS[:round] = ->(args : Array(String)) : String {
        raise ArgumentError.new("round requires at least 1 argument") if args.empty?
        value = args[0].to_f?
        raise ArgumentError.new("round first argument must be numeric") unless value
        precision = args[1]?.try(&.to_i?) || 0
        value.round(precision).to_s
      }

      FUNCTIONS[:ceil] = ->(args : Array(String)) : String {
        raise ArgumentError.new("ceil requires exactly 1 argument") if args.size != 1
        value = args[0].to_f?
        raise ArgumentError.new("ceil argument must be numeric") unless value
        value.ceil.to_s
      }

      FUNCTIONS[:floor] = ->(args : Array(String)) : String {
        raise ArgumentError.new("floor requires exactly 1 argument") if args.size != 1
        value = args[0].to_f?
        raise ArgumentError.new("floor argument must be numeric") unless value
        value.floor.to_s
      }

      FUNCTIONS[:abs] = ->(args : Array(String)) : String {
        raise ArgumentError.new("abs requires exactly 1 argument") if args.size != 1
        value = args[0].to_f?
        raise ArgumentError.new("abs argument must be numeric") unless value
        value.abs.to_s
      }

      FUNCTIONS[:sqrt] = ->(args : Array(String)) : String {
        raise ArgumentError.new("sqrt requires exactly 1 argument") if args.size != 1
        value = args[0].to_f?
        raise ArgumentError.new("sqrt argument must be numeric") unless value
        raise ArgumentError.new("sqrt of negative number") if value < 0.0
        Math.sqrt(value).to_s
      }

      FUNCTIONS[:pow] = ->(args : Array(String)) : String {
        raise ArgumentError.new("pow requires exactly 2 arguments") if args.size != 2
        base = args[0].to_f?
        exponent = args[1].to_f?
        raise ArgumentError.new("pow arguments must be numeric") if !base || !exponent
        (base ** exponent).to_s
      }

      FUNCTIONS[:min] = ->(args : Array(String)) : String {
        raise ArgumentError.new("min requires at least 1 argument") if args.empty?
        values = args.compact_map(&.to_f?)
        raise ArgumentError.new("min arguments must be numeric") if values.size != args.size
        values.min.to_s
      }

      FUNCTIONS[:max] = ->(args : Array(String)) : String {
        raise ArgumentError.new("max requires at least 1 argument") if args.empty?
        values = args.compact_map(&.to_f?)
        raise ArgumentError.new("max arguments must be numeric") if values.size != args.size
        values.max.to_s
      }

      FUNCTIONS[:sum] = ->(args : Array(String)) : String {
        raise ArgumentError.new("sum requires at least 1 argument") if args.empty?
        values = args.compact_map(&.to_f?)
        raise ArgumentError.new("sum arguments must be numeric") if values.size != args.size
        values.sum.to_s
      }
    end

    # TIME FUNCTIONS - Leveraging Crystal's Time module
    private def self.register_time_functions
      FUNCTIONS[:now] = ->(args : Array(String)) : String {
        Time.utc.to_s("%Y-%m-%d %H:%M:%S")
      }

      FUNCTIONS[:date] = ->(args : Array(String)) : String {
        format = args[0]? || "%Y-%m-%d"
        Time.utc.to_s(format)
      }

      FUNCTIONS[:time] = ->(args : Array(String)) : String {
        format = args[0]? || "%H:%M:%S"
        Time.utc.to_s(format)
      }

      FUNCTIONS[:datetime] = ->(args : Array(String)) : String {
        format = args[0]? || "%Y-%m-%d %H:%M:%S"
        Time.utc.to_s(format)
      }

      FUNCTIONS[:timestamp] = ->(args : Array(String)) : String {
        Time.utc.to_unix.to_s
      }

      FUNCTIONS[:rfc3339] = ->(args : Array(String)) : String {
        Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
      }

      FUNCTIONS[:iso8601] = ->(args : Array(String)) : String {
        Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
      }

      FUNCTIONS[:ago] = ->(args : Array(String)) : String {
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

      FUNCTIONS[:time_ago] = ->(args : Array(String)) : String {
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
      FUNCTIONS[:"has_key"] = ->(args : Array(String)) : String {
        # This would need context from the template processor
        "false" # Placeholder
      }

      FUNCTIONS[:keys] = ->(args : Array(String)) : String {
        # This would need context from the template processor
        "" # Placeholder
      }

      FUNCTIONS[:values] = ->(args : Array(String)) : String {
        # This would need context from the template processor
        "" # Placeholder
      }
    end

    # URL FUNCTIONS - Complete URI-based implementation
    private def self.register_url_functions
      FUNCTIONS[:urlize] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      }

      FUNCTIONS[:"relative_url"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        base = args[1]? || ""
        return url if url.starts_with?("http")

        base_uri = URI.parse(base)
        target_uri = URI.parse(url)
        base_uri.relativize(target_uri).to_s
      }

      FUNCTIONS[:"absolute_url"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        base = args[1]? || ""
        return url if url.starts_with?("http")

        base_uri = URI.parse(base)
        target_uri = URI.parse(url)
        base_uri.resolve(target_uri).to_s
      }

      FUNCTIONS[:"url_encode"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        URI.encode_path(str)
      }

      FUNCTIONS[:"url_decode"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        URI.decode(str)
      }

      # NEW URI-BASED FUNCTIONS
      FUNCTIONS[:"url_normalize"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        URI.parse(url).normalize.to_s
      }

      FUNCTIONS[:"url_scheme"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        URI.parse(url).scheme || ""
      }

      FUNCTIONS[:"url_host"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        URI.parse(url).host || ""
      }

      FUNCTIONS[:"url_port"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        port = URI.parse(url).port
        port ? port.to_s : ""
      }

      FUNCTIONS[:"url_path"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        URI.parse(url).path || ""
      }

      FUNCTIONS[:"url_query"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        URI.parse(url).query || ""
      }

      FUNCTIONS[:"url_fragment"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        URI.parse(url).fragment || ""
      }

      FUNCTIONS[:"is_absolute_url"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        URI.parse(url).absolute?.to_s
      }

      FUNCTIONS[:"is_valid_url"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        begin
          uri = URI.parse(url)
          (!uri.opaque? && !uri.scheme.nil?).to_s
        rescue
          "false"
        end
      }

      FUNCTIONS[:"url_join"] = ->(args : Array(String)) : String {
        base = args[0]? || ""
        path = args[1]? || ""
        URI.parse(base).resolve(path).to_s
      }

      FUNCTIONS[:"url_components"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        uri = URI.parse(url)
        {
          scheme:   uri.scheme || "",
          host:     uri.host || "",
          port:     uri.port || "",
          path:     uri.path || "",
          query:    uri.query || "",
          fragment: uri.fragment || "",
          user:     uri.user || "",
          password: uri.password ? "***" : "",
        }.to_h.to_json
      }

      FUNCTIONS[:"query_params"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        uri = URI.parse(url)
        uri.query_params.to_h.to_json
      }

      FUNCTIONS[:"update_query_param"] = ->(args : Array(String)) : String {
        url = args[0] || ""
        key = args[1]? || ""
        value = args[2]? || ""

        uri = URI.parse(url)
        uri.update_query_params do |params|
          params[key] = [value]
        end
        uri.to_s
      }
    end

    # LOGIC FUNCTIONS - Enhanced logical operations
    private def self.register_logic_functions
      FUNCTIONS[:eq] = ->(args : Array(String)) : String {
        args[0] == args[1] ? "true" : "false"
      }

      FUNCTIONS[:ne] = ->(args : Array(String)) : String {
        args[0] != args[1] ? "true" : "false"
      }

      FUNCTIONS[:gt] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a > b ? "true" : "false"
      }

      FUNCTIONS[:lt] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a < b ? "true" : "false"
      }

      FUNCTIONS[:gte] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a >= b ? "true" : "false"
      }

      FUNCTIONS[:lte] = ->(args : Array(String)) : String {
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a <= b ? "true" : "false"
      }

      FUNCTIONS[:and] = ->(args : Array(String)) : String {
        args.all? { |arg| arg == "true" || arg == "1" || arg != "" } ? "true" : "false"
      }

      FUNCTIONS[:or] = ->(args : Array(String)) : String {
        args.any? { |arg| arg == "true" || arg == "1" || arg != "" } ? "true" : "false"
      }

      FUNCTIONS[:not] = ->(args : Array(String)) : String {
        arg = args[0]? || ""
        (arg == "true" || arg == "1" || arg != "") ? "false" : "true"
      }

      FUNCTIONS[:contains] = ->(args : Array(String)) : String {
        haystack = args[0]? || ""
        needle = args[1]? || ""
        haystack.includes?(needle) ? "true" : "false"
      }

      FUNCTIONS[:"starts_with"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        prefix = args[1]? || ""
        str.starts_with?(prefix) ? "true" : "false"
      }

      FUNCTIONS[:"ends_with"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        suffix = args[1]? || ""
        str.ends_with?(suffix) ? "true" : "false"
      }
    end

    # TYPE FUNCTIONS - Enhanced type handling
    private def self.register_type_functions
      FUNCTIONS[:string] = ->(args : Array(String)) : String {
        args[0] || ""
      }

      FUNCTIONS[:int] = ->(args : Array(String)) : String {
        raise ArgumentError.new("int requires exactly 1 argument") if args.size != 1
        value = args[0].to_i?
        raise ArgumentError.new("int argument must be numeric") unless value
        value.to_s
      }

      FUNCTIONS[:float] = ->(args : Array(String)) : String {
        raise ArgumentError.new("float requires exactly 1 argument") if args.size != 1
        value = args[0].to_f?
        raise ArgumentError.new("float argument must be numeric") unless value
        value.to_s
      }

      FUNCTIONS[:bool] = ->(args : Array(String)) : String {
        raise ArgumentError.new("bool requires exactly 1 argument") if args.size != 1
        arg = args[0]
        (arg == "true" || arg == "1" || arg != "") ? "true" : "false"
      }

      FUNCTIONS[:array] = ->(args : Array(String)) : String {
        args.join(",")
      }

      FUNCTIONS[:size] = ->(args : Array(String)) : String {
        raise ArgumentError.new("size requires exactly 1 argument") if args.size != 1
        args[0].size.to_s
      }

      FUNCTIONS[:empty] = ->(args : Array(String)) : String {
        raise ArgumentError.new("empty requires exactly 1 argument") if args.size != 1
        arg = args[0]
        arg.empty? ? "true" : "false"
      }

      FUNCTIONS[:blank] = ->(args : Array(String)) : String {
        raise ArgumentError.new("blank requires exactly 1 argument") if args.size != 1
        arg = args[0]
        arg.strip.empty? ? "true" : "false"
      }
    end

    # MARKDOWN FUNCTIONS - Markdown processing
    private def self.register_markdown_functions
      FUNCTIONS[:markdownify] = ->(args : Array(String)) : String {
        markdown = args[0]? || ""
        begin
          # This would use the Markd library for processing
          markdown # Placeholder - would need Markd integration
        rescue
          markdown
        end
      }

      FUNCTIONS[:"strip_html"] = ->(args : Array(String)) : String {
        html = args[0]? || ""
        html.gsub(/<[^>]*>/, "")
      }

      FUNCTIONS[:"escape_html"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        HTML.escape(str)
      }

      FUNCTIONS[:"unescape_html"] = ->(args : Array(String)) : String {
        str = args[0]? || ""
        HTML.unescape(str)
      }
    end

    # TEXT FUNCTIONS - Advanced text processing
    private def self.register_text_functions
      FUNCTIONS[:"word_count"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        text.split.size.to_s
      }

      FUNCTIONS[:"reading_time"] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        words_per_minute = args[1]?.try(&.to_i?) || 200
        minutes = (text.split.size.to_f / words_per_minute).ceil
        minutes == 1 ? "1 min read" : "#{minutes} min read"
      }

      FUNCTIONS[:first] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        count = args[1]?.try(&.to_i?) || 1
        text.split.first(count).join(" ")
      }

      FUNCTIONS[:last] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        count = args[1]?.try(&.to_i?) || 1
        text.split.last(count).join(" ")
      }

      FUNCTIONS[:replace] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        search = args[1]? || ""
        replace = args[2]? || ""
        text.gsub(search, replace)
      }

      FUNCTIONS[:remove] = ->(args : Array(String)) : String {
        text = args[0]? || ""
        search = args[1]? || ""
        text.gsub(search, "")
      }
    end

    # FILE FUNCTIONS - File system operations
    private def self.register_file_functions
      FUNCTIONS[:"file_exists"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        File.exists?(file_path) ? "true" : "false"
      }

      FUNCTIONS[:"file_size"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        begin
          File.size(file_path).to_s
        rescue
          "0"
        end
      }

      FUNCTIONS[:"file_extension"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        File.extname(file_path)
      }

      FUNCTIONS[:"file_extname"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        Path[file_path].extension
      }

      FUNCTIONS[:"file_basename"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        Path[file_path].basename
      }

      FUNCTIONS[:"file_dirname"] = ->(args : Array(String)) : String {
        file_path = args[0]? || ""
        Path[file_path].parent.to_s
      }
    end
  end
end
