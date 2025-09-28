require "../spec_helper"
require "../../src/lapis/safe_cast"
require "../../src/lapis/functions"

describe "Char API Integration" do
  before_each do
    Lapis::Functions.setup
  end

  describe "End-to-end Char API functionality" do
    it "processes character validation through SafeCast and Functions", tags: [TestTags::INTEGRATION] do
      # Test SafeCast character validation
      test_string = "Hello123World"

      # SafeCast validation
      Lapis::SafeCast.alphanumeric_string?(test_string).should be_true
      Lapis::SafeCast.numeric_string?(test_string).should be_false
      Lapis::SafeCast.alphabetic_string?(test_string).should be_false

      # Character counting through SafeCast
      uppercase_count = Lapis::SafeCast.count_uppercase(test_string)
      lowercase_count = Lapis::SafeCast.count_lowercase(test_string)
      uppercase_count.should eq(2)
      lowercase_count.should eq(8)
      (lowercase_count + uppercase_count).should eq(10)

      # Character extraction through SafeCast
      digits = Lapis::SafeCast.extract_digits(test_string)
      letters = Lapis::SafeCast.extract_letters(test_string)
      digits.should eq("123")
      letters.should eq("HelloWorld")

      # Template functions using Char API
      char_count = Lapis::Functions.call("char_count", [test_string])
      char_count_alpha = Lapis::Functions.call("char_count_alpha", [test_string])
      char_count_digit = Lapis::Functions.call("char_count_digit", [test_string])

      char_count.to_i.should eq(test_string.size)
      char_count_alpha.to_i.should eq(10)
      char_count_digit.to_i.should eq(3)

      # Validation functions
      is_alphanumeric = Lapis::Functions.call("is_alphanumeric", [test_string])
      is_numeric = Lapis::Functions.call("is_numeric", [test_string])
      is_alpha = Lapis::Functions.call("is_alpha", [test_string])

      is_alphanumeric.should eq("true")
      is_numeric.should eq("false")
      is_alpha.should eq("false")
    end

    it "handles Unicode characters correctly with Char API", tags: [TestTags::INTEGRATION] do
      unicode_string = "Hello 世界 123"

      # Character counting should handle Unicode correctly
      char_count = Lapis::Functions.call("char_count", [unicode_string])
      char_count_alpha = Lapis::Functions.call("char_count_alpha", [unicode_string])

      char_count.to_i.should eq(unicode_string.size)
      char_count_alpha.to_i.should eq(7) # H, e, l, l, o, 世, 界

      # SafeCast should handle Unicode
      Lapis::SafeCast.count_lowercase(unicode_string).should eq(4) # e, l, l, o
      Lapis::SafeCast.count_uppercase(unicode_string).should eq(1) # H
    end

    it "validates identifiers using improved Char API methods", tags: [TestTags::INTEGRATION] do
      valid_identifiers = ["valid_identifier", "_private", "CamelCase", "var123"]
      invalid_identifiers = ["123invalid", "invalid-name", "invalid.name", ""]

      valid_identifiers.each do |identifier|
        # SafeCast validation
        Lapis::SafeCast.valid_symbol?(identifier).should be_true
        Lapis::SafeCast.valid_identifier?(identifier).should be_true

        # Should start with letter or underscore
        if identifier.starts_with?('_')
          # Underscore case - not uppercase
          Lapis::SafeCast.starts_with_uppercase?(identifier).should be_false
        elsif identifier.starts_with?('C') || identifier.starts_with?('v')
          # These should start with uppercase/lowercase respectively
          if identifier.starts_with?('C')
            Lapis::SafeCast.starts_with_uppercase?(identifier).should be_true
          else
            Lapis::SafeCast.starts_with_uppercase?(identifier).should be_false
          end
        end
      end

      invalid_identifiers.each do |identifier|
        Lapis::SafeCast.valid_symbol?(identifier).should be_false
        Lapis::SafeCast.valid_identifier?(identifier).should be_false
      end
    end

    it "improves string transformations with Char API", tags: [TestTags::INTEGRATION] do
      test_cases = [
        {input: "HelloWorld", underscore: "hello_world", dasherize: "hello-world"},
        {input: "CamelCase", underscore: "camel_case", dasherize: "camel-case"},
        {input: "XMLHttpRequest", underscore: "xml_http_request", dasherize: "xml-http-request"},
      ]

      test_cases.each do |test_case|
        # Test improved underscore function
        underscore_result = Lapis::Functions.call("underscore", [test_case[:input]])
        underscore_result.should eq(test_case[:underscore])

        # Test improved dasherize function
        dasherize_result = Lapis::Functions.call("dasherize", [test_case[:input]])
        dasherize_result.should eq(test_case[:dasherize])
      end
    end

    it "provides comprehensive character analysis", tags: [TestTags::INTEGRATION] do
      test_string = "Hello World 123!"

      # Get comprehensive character analysis
      total_chars = Lapis::Functions.call("char_count", [test_string])
      alpha_chars = Lapis::Functions.call("char_count_alpha", [test_string])
      digit_chars = Lapis::Functions.call("char_count_digit", [test_string])
      upper_chars = Lapis::Functions.call("char_count_upper", [test_string])
      lower_chars = Lapis::Functions.call("char_count_lower", [test_string])
      whitespace_chars = Lapis::Functions.call("char_count_whitespace", [test_string])

      # Verify counts (test_string = "Hello World 123!" = 16 chars)
      total_chars.to_i.should eq(16)
      alpha_chars.to_i.should eq(10)
      digit_chars.to_i.should eq(3)
      upper_chars.to_i.should eq(2)
      lower_chars.to_i.should eq(8)
      whitespace_chars.to_i.should eq(2)

      # Verify math: alpha + digits + whitespace + punctuation = total
      (alpha_chars.to_i + digit_chars.to_i + whitespace_chars.to_i + 1).should eq(total_chars.to_i)

      # Verify case distribution
      (upper_chars.to_i + lower_chars.to_i).should eq(alpha_chars.to_i)
    end

    it "maintains backward compatibility with existing functions", tags: [TestTags::INTEGRATION] do
      # Test that existing functions still work
      result = Lapis::Functions.call("upper", ["hello"])
      result.should eq("HELLO")

      result = Lapis::Functions.call("lower", ["WORLD"])
      result.should eq("world")

      result = Lapis::Functions.call("trim", ["  spaced  "])
      result.should eq("spaced")

      # Test that SafeCast existing methods still work
      result = Lapis::SafeCast.cast_or_nil("hello", String)
      result.should eq("hello")
    end
  end

  describe "Performance characteristics of Char API" do
    it "handles large strings efficiently", tags: [TestTags::INTEGRATION] do
      large_string = "a" * 1000 + "1" * 500 + "A" * 250

      # Character counting should be efficient
      start_time = Time.monotonic
      char_count = Lapis::Functions.call("char_count", [large_string])
      alpha_count = Lapis::Functions.call("char_count_alpha", [large_string])
      digit_count = Lapis::Functions.call("char_count_digit", [large_string])
      end_time = Time.monotonic

      # Should complete quickly (less than 100ms for this size)
      duration = (end_time - start_time).total_milliseconds
      duration.should be < 100.0

      # Verify correct counts
      char_count.to_i.should eq(1750)
      alpha_count.to_i.should eq(1250)
      digit_count.to_i.should eq(500)
    end
  end
end
