require "./logger"
require "./exceptions"
require "string"

module Lapis
  # Safe type casting utilities to prevent TypeCastError exceptions
  module SafeCast
    # Safely cast an object to a specific type, returning nil if the cast fails
    def self.cast_or_nil(object, target_type : T.class) forall T
      return nil if object.nil?
      object.is_a?(T) ? object.as(T) : nil
    end

    # Safely cast an object to a specific type, returning a default value if the cast fails
    def self.cast_or_default(object, target_type : T.class, default : T) : T forall T
      return default if object.nil?
      object.is_a?(T) ? object.as(T) : default
    end

    # Safely cast an object to a specific type, raising a Lapis TypeCastError if it fails
    def self.cast_or_raise(object, target_type : T.class, context : String = "") : T forall T
      raise ArgumentError.new("Cannot cast nil to #{T.name}") if object.nil?
      if object.is_a?(T)
        Logger.type_cast_success("cast_or_raise", object.class.name, T.name, context: context)
        object.as(T)
      else
        Logger.type_cast_error("cast_or_raise", object.class.name, T.name, object.inspect, context: context)
        error_msg = "Failed to cast #{object.class.name} to #{T.name}"
        error_msg += " (#{context})" unless context.empty?
        raise ArgumentError.new(error_msg)
      end
    end

    # Safely cast JSON::Any to a specific type
    def self.cast_json_any(object : JSON::Any, target_type : T.class) forall T
      # Use specific JSON::Any methods for type casting
      return nil if object.nil?
      # Handle common types explicitly
      if T == String
        object.as_s?
      elsif T == Int32
        object.as_i?
      elsif T == Int64
        object.as_i64?
      elsif T == Float32 || T == Float64
        object.as_f?
      elsif T == Bool
        object.as_bool?
      else
        # For other types, return nil
        nil
      end
    end

    # Safely cast YAML::Any to a specific type
    def self.cast_yaml_any(object : YAML::Any, target_type : T.class) forall T
      # Use specific YAML::Any methods for type casting
      return nil if object.nil?
      # Handle common types explicitly
      if T == String
        object.as_s?
      elsif T == Int32
        object.as_i?
      elsif T == Int64
        object.as_i64?
      elsif T == Float32 || T == Float64
        object.as_f?
      elsif T == Bool
        object.as_bool?
      else
        # For other types, return nil
        nil
      end
    end

    # Safely cast a string to a symbol, returning nil if the conversion fails
    def self.string_to_symbol(str : String) : Symbol?
      return nil if str.empty?
      str.to_sym
    rescue
      nil
    end

    # Safely cast a symbol to a string
    def self.symbol_to_string(sym : Symbol) : String
      sym.to_s
    end

    # Check if a string can be converted to a valid symbol using Char API
    def self.valid_symbol?(str : String) : Bool
      raise ArgumentError.new("String cannot be nil") if str.nil?
      return false if str.empty?
      # Use Char API for more efficient character-by-character validation
      chars = str.chars
      return false if chars.empty?
      # First character must be letter or underscore
      first_char = chars[0]
      return false unless first_char.letter? || first_char == '_'
      # Remaining characters must be letters, digits, or underscores
      range = 1...chars.size
      range.all? { |i| chars[i].letter? || chars[i].number? || chars[i] == '_' }
    end

    # Safely cast an object to a symbol, returning nil if the cast fails
    def self.cast_to_symbol(object) : Symbol?
      case object
      when Symbol
        object
      when String
        string_to_symbol(object)
      else
        nil
      end
    end

    # Safely cast an object to a string, returning nil if the cast fails
    def self.cast_to_string(object) : String?
      case object
      when String
        object
      when Symbol
        symbol_to_string(object)
      else
        object.try(&.to_s)
      end
    end

    # Character-level validation methods using Char API

    # Check if a string contains only digits
    def self.numeric_string?(str : String) : Bool
      raise ArgumentError.new("String cannot be nil") if str.nil?
      return false if str.empty?
      str.chars.all?(&.number?)
    end

    # Check if a string contains only alphabetic characters
    def self.alphabetic_string?(str : String) : Bool
      raise ArgumentError.new("String cannot be nil") if str.nil?
      return false if str.empty?
      str.chars.all?(&.letter?)
    end

    # Check if a string contains only alphanumeric characters
    def self.alphanumeric_string?(str : String) : Bool
      raise ArgumentError.new("String cannot be nil") if str.nil?
      return false if str.empty?
      str.chars.all? { |char| char.letter? || char.number? }
    end

    # Check if a string is a valid identifier (letters, digits, underscores, starting with letter/underscore)
    def self.valid_identifier?(str : String) : Bool
      return false if str.empty?
      chars = str.chars
      first_char = chars[0]
      return false unless first_char.letter? || first_char == '_'
      range = 1...chars.size
      range.all? { |i| chars[i].letter? || chars[i].number? || chars[i] == '_' }
    end

    # Check if a string contains only whitespace
    def self.whitespace_string?(str : String) : Bool
      return true if str.empty?
      str.chars.all?(&.whitespace?)
    end

    # Extract digits from a string using Char API
    def self.extract_digits(str : String) : String
      str.chars.select(&.number?).join
    end

    # Extract letters from a string using Char API
    def self.extract_letters(str : String) : String
      str.chars.select(&.letter?).join
    end

    # Convert first character to uppercase using Char API
    def self.capitalize_first(str : String) : String
      return str if str.empty?
      chars = str.chars
      range = 1...chars.size
      chars[0].upcase.to_s + range.map { |i| chars[i] }.join
    end

    # Check if string starts with uppercase letter using Char API
    def self.starts_with_uppercase?(str : String) : Bool
      return false if str.empty?
      str.chars[0].uppercase?
    end

    # Count uppercase letters in string using Char API
    def self.count_uppercase(str : String) : Int32
      str.chars.count(&.uppercase?)
    end

    # Count lowercase letters in string using Char API
    def self.count_lowercase(str : String) : Int32
      str.chars.count(&.lowercase?)
    end

    # Unicode validation and normalization methods
    def self.validate_utf8_string?(str : String) : Bool
      str.valid_encoding?
    end

    def self.normalize_unicode(str : String, form : Unicode::NormalizationForm = :nfc) : String
      str.unicode_normalize(form)
    end

    def self.unicode_normalized?(str : String, form : Unicode::NormalizationForm = :nfc) : Bool
      str.unicode_normalized?(form)
    end

    # Advanced character analysis using Crystal's String API
    def self.advanced_char_analysis(str : String) : NamedTuple(
      total_chars: Int32,
      total_bytes: Int32,
      unicode_codepoints: Array(Int32),
      whitespace_count: Int32,
      letter_count: Int32,
      number_count: Int32,
      symbol_count: Int32,
      uppercase_count: Int32,
      lowercase_count: Int32)
      {
        total_chars:        str.size,
        total_bytes:        str.bytesize,
        unicode_codepoints: str.codepoints.to_a,
        whitespace_count:   str.chars.count(&.whitespace?),
        letter_count:       str.chars.count(&.letter?),
        number_count:       str.chars.count(&.number?),
        symbol_count:       str.chars.count { |c| !c.letter? && !c.number? && !c.whitespace? },
        uppercase_count:    str.chars.count(&.uppercase?),
        lowercase_count:    str.chars.count(&.lowercase?),
      }
    end

    # Performance-optimized string operations
    def self.optimized_slugify(str : String) : String
      return "" if str.empty?

      normalized = str.unicode_normalize(:nfd)
      chars = normalized.chars
      result = [] of Char
      last_was_separator = false
      first_char = true

      chars.each do |char|
        if char.letter? || char.number?
          result << char.downcase
          last_was_separator = false
          first_char = false
        elsif !last_was_separator && !first_char
          result << '-'
          last_was_separator = true
        end
      end

      # Remove leading/trailing dashes
      result.join.lstrip('-').rstrip('-')
    end

    # UTF-16 conversion for internationalization
    def self.to_utf16_string(str : String) : String
      utf16_slice = str.to_utf16
      utf16_slice.to_a.map(&.to_s).join(",")
    end

    # Advanced string manipulation using Crystal's String methods
    def self.translate_string(str : String, from : String, to : String) : String
      str.tr(from, to)
    end

    def self.squeeze_string(str : String, chars : String = "") : String
      chars.empty? ? str.squeeze : str.squeeze(chars)
    end

    def self.delete_chars(str : String, chars : String) : String
      str.delete(chars)
    end

    # Memory-efficient string building for large operations
    def self.build_string(&) : String
      String.build do |io|
        yield io
      end
    end
  end
end
