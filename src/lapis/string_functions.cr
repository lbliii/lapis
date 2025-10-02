require "html"
require "./safe_cast"
require "./function_registry"

module Lapis
  # String manipulation functions with Unicode support and performance optimizations
  module StringFunctions
    extend self

    def register_functions
      # Basic string manipulation with Unicode support
      FunctionRegistry.register_function(:upper, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        str.upcase
      end

      FunctionRegistry.register_function(:lower, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        str.downcase
      end

      FunctionRegistry.register_function(:title, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        result = String.build do |io|
          str.split(/\s+/).each_with_index do |word, index|
            io << " " if index > 0
            io << word.capitalize
          end
        end
        FunctionRegistry::STRING_POOL.get(result)
      end

      FunctionRegistry.register_function(:trim, 1) do |args|
        str = args[0] || ""
        str.strip
      end

      FunctionRegistry.register_function(:lstrip, 1) do |args|
        str = args[0] || ""
        str.lstrip
      end

      FunctionRegistry.register_function(:rstrip, 1) do |args|
        str = args[0] || ""
        str.rstrip
      end

      FunctionRegistry.register_function(:chomp, 2) do |args|
        str = args[0] || ""
        suffix = args[1]? || "\n"
        str.chomp(suffix)
      end

      # Enhanced slugify with Unicode normalization
      FunctionRegistry.register_function(:slugify, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        result = SafeCast.optimized_slugify(str)
        FunctionRegistry::STRING_POOL.get(result)
      end

      FunctionRegistry.register_function(:camelize, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        String.build do |io|
          str.split(/[-_\s]+/).each do |word|
            io << word.capitalize
          end
        end
      end

      FunctionRegistry.register_function(:underscore, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        str.underscore
      end

      FunctionRegistry.register_function(:dasherize, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        str.underscore.tr("_", "-")
      end

      # Unicode-aware functions
      FunctionRegistry.register_function(:unicode_normalize, 2) do |args|
        str = args[0] || ""
        next "" if str.empty?
        form_str = args[1]? || "nfc"
        form = case form_str.downcase
               when "nfd"  then Unicode::NormalizationForm::NFD
               when "nfkc" then Unicode::NormalizationForm::NFKC
               when "nfkd" then Unicode::NormalizationForm::NFKD
               else             Unicode::NormalizationForm::NFC
               end
        str.unicode_normalize(form)
      end

      FunctionRegistry.register_function(:validate_utf8, 1) do |args|
        str = args[0] || ""
        str.valid_encoding?.to_s
      end

      # Advanced string manipulation
      FunctionRegistry.register_function(:tr, 3) do |args|
        str = args[0] || ""
        from = args[1]? || ""
        to = args[2]? || ""
        str.tr(from, to)
      end

      FunctionRegistry.register_function(:squeeze, 2) do |args|
        str = args[0] || ""
        chars = args[1]? || ""
        chars.empty? ? str.squeeze : str.squeeze(chars)
      end

      FunctionRegistry.register_function(:delete, 2) do |args|
        str = args[0] || ""
        chars = args[1]? || ""
        str.delete(chars)
      end

      # Character analysis functions
      FunctionRegistry.register_function(:char_count, 1) do |args|
        str = args[0] || ""
        str.size.to_s
      end

      FunctionRegistry.register_function(:byte_count, 1) do |args|
        str = args[0] || ""
        str.bytesize.to_s
      end

      FunctionRegistry.register_function(:codepoint_count, 1) do |args|
        str = args[0] || ""
        str.codepoints.size.to_s
      end

      # UTF-16 conversion for internationalization
      FunctionRegistry.register_function(:to_utf16, 1) do |args|
        str = args[0] || ""
        next "" if str.empty?
        SafeCast.to_utf16_string(str)
      end

      # Performance-optimized string operations
      FunctionRegistry.register_function(:reverse, 1) do |args|
        str = args[0] || ""
        str.reverse
      end

      FunctionRegistry.register_function(:repeat, 2) do |args|
        str = args[0] || ""
        count = args[1]?.try(&.to_i?) || 1
        str * count
      end

      # String building for complex operations
      FunctionRegistry.register_function(:build_string, 0) do |args|
        SafeCast.build_string do |io|
          args.each { |arg| io << arg }
        end
      end

      FunctionRegistry.register_function(:pluralize, 2) do |args|
        raise ArgumentError.new("pluralize requires at least 1 argument") if args.empty?
        str = args[0]
        count = args[1]?.try(&.to_i?) || 1
        count == 1 ? str : "#{str}s"
      end

      FunctionRegistry.register_function(:singularize, 1) do |args|
        raise ArgumentError.new("singularize requires exactly 1 argument") if args.size != 1
        str = args[0]
        str.ends_with?("s") ? str.chomp("s") : str
      end

      FunctionRegistry.register_function(:truncate, 3) do |args|
        raise ArgumentError.new("truncate requires at least 1 argument") if args.empty?
        str = args[0]
        length = args[1]?.try(&.to_i?) || 50
        raise ArgumentError.new("truncate length must be positive") if length < 0
        omission = args[2]? || "..."
        str.size > length ? "#{str[0, length - omission.size]}#{omission}" : str
      end

      FunctionRegistry.register_function(:"truncatewords", 3) do |args|
        raise ArgumentError.new("truncatewords requires at least 1 argument") if args.empty?
        str = args[0]
        count = args[1]?.try(&.to_i?) || 15
        raise ArgumentError.new("truncatewords count must be positive") if count < 0
        omission = args[2]? || "..."
        words = str.split
        words.size > count ? "#{words.first(count).join(" ")}#{omission}" : str
      end

      FunctionRegistry.register_function(:"strip_newlines", 1) do |args|
        str = args[0] || ""
        str.gsub(/\n+/, " ").strip
      end

      FunctionRegistry.register_function(:"newline_to_br", 1) do |args|
        str = args[0] || ""
        str.gsub(/\n/, "<br>")
      end

      FunctionRegistry.register_function(:escape, 1) do |args|
        str = args[0] || ""
        HTML.escape(str)
      end

      FunctionRegistry.register_function(:unescape, 1) do |args|
        str = args[0] || ""
        HTML.unescape(str)
      end

      # Character-based utility functions using Char API
      FunctionRegistry.register_function(:"char_count_alpha", 1) do |args|
        str = args[0] || ""
        str.chars.count(&.letter?).to_s
      end

      FunctionRegistry.register_function(:"char_count_digit", 1) do |args|
        str = args[0] || ""
        str.chars.count(&.number?).to_s
      end

      FunctionRegistry.register_function(:"char_count_upper", 1) do |args|
        str = args[0] || ""
        str.chars.count(&.uppercase?).to_s
      end

      FunctionRegistry.register_function(:"char_count_lower", 1) do |args|
        str = args[0] || ""
        str.chars.count(&.lowercase?).to_s
      end

      FunctionRegistry.register_function(:"char_count_whitespace", 1) do |args|
        str = args[0] || ""
        str.chars.count(&.whitespace?).to_s
      end

      FunctionRegistry.register_function(:"extract_digits", 1) do |args|
        str = args[0] || ""
        str.chars.select(&.number?).join
      end

      FunctionRegistry.register_function(:"extract_letters", 1) do |args|
        str = args[0] || ""
        str.chars.select(&.letter?).join
      end

      FunctionRegistry.register_function(:"is_numeric", 1) do |args|
        str = args[0] || ""
        (str.empty? ? false : str.chars.all?(&.number?)).to_s
      end

      FunctionRegistry.register_function(:"is_alpha", 1) do |args|
        str = args[0] || ""
        (str.empty? ? false : str.chars.all?(&.letter?)).to_s
      end

      FunctionRegistry.register_function(:"is_alphanumeric", 1) do |args|
        str = args[0] || ""
        (str.empty? ? false : str.chars.all? { |char| char.letter? || char.number? }).to_s
      end

      FunctionRegistry.register_function(:"starts_with_upper", 1) do |args|
        str = args[0] || ""
        (str.empty? ? false : str.chars[0].uppercase?).to_s
      end
    end
  end
end
