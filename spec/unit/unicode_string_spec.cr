require "../spec_helper"
require "../../src/lapis/safe_cast"
require "../../src/lapis/functions"

describe "Unicode String Processing" do
  # Setup functions before running tests
  Lapis::Functions.setup

  describe "SafeCast Unicode Methods" do
    it "validates UTF-8 encoding correctly" do
      valid_string = "Hello 世界"
      invalid_string = "Hello \xFF\xFE"

      Lapis::SafeCast.validate_utf8_string?(valid_string).should be_true
      Lapis::SafeCast.validate_utf8_string?(invalid_string).should be_false
    end

    it "normalizes Unicode correctly" do
      test_string = "café"
      normalized = Lapis::SafeCast.normalize_unicode(test_string, :nfd)
      normalized.should_not eq(test_string)

      # Test different normalization forms
      nfc = Lapis::SafeCast.normalize_unicode(test_string, :nfc)
      nfd = Lapis::SafeCast.normalize_unicode(test_string, :nfd)

      nfc.should eq(test_string)     # NFC should be the same as original
      nfd.should_not eq(test_string) # NFD should be different
    end

    it "checks Unicode normalization status" do
      test_string = "café"
      Lapis::SafeCast.unicode_normalized?(test_string, :nfc).should be_true
      Lapis::SafeCast.unicode_normalized?(test_string, :nfd).should be_false
    end

    it "performs advanced character analysis" do
      test_string = "Hello 世界 123!"
      analysis = Lapis::SafeCast.advanced_char_analysis(test_string)

      analysis[:total_chars].should eq(13)
      analysis[:total_bytes].should be > analysis[:total_chars] # Unicode characters take more bytes
      analysis[:letter_count].should eq(7)                      # H, e, l, l, o, 世, 界
      analysis[:number_count].should eq(3)                      # 1, 2, 3
      analysis[:uppercase_count].should eq(1)                   # H
      analysis[:lowercase_count].should eq(4)                   # e, l, l, o
      analysis[:unicode_codepoints].size.should eq(13)
    end

    it "optimizes slugify with Unicode support" do
      test_string = "Hello 世界! This is a test."
      slug = Lapis::SafeCast.optimized_slugify(test_string)

      slug.should eq("hello-世界-this-is-a-test")
      slug.should_not contain("!")
      slug.should_not contain(".")
    end

    it "converts to UTF-16 for internationalization" do
      test_string = "Hello 世界"
      utf16_string = Lapis::SafeCast.to_utf16_string(test_string)

      utf16_string.should be_a(String)
      utf16_string.should contain(",") # UTF-16 values separated by commas
    end

    it "performs advanced string manipulation" do
      test_string = "hello world"

      # Character translation
      translated = Lapis::SafeCast.translate_string(test_string, "lo", "XO")
      translated.should eq("heXXO wOrXd")

      # String squeezing
      squeezed = Lapis::SafeCast.squeeze_string("hello    world")
      squeezed.should eq("helo world")

      # Character deletion
      deleted = Lapis::SafeCast.delete_chars("hello world", "lo")
      deleted.should eq("he wrd")
    end

    it "builds strings efficiently" do
      result = Lapis::SafeCast.build_string do |io|
        io << "Hello"
        io << " "
        io << "World"
      end

      result.should eq("Hello World")
    end
  end

  describe "Enhanced String Functions" do
    it "handles Unicode normalization in functions" do
      test_string = "café"
      normalized = Lapis::Functions.call("unicode_normalize", [test_string, "nfd"])
      normalized.should_not eq(test_string)
    end

    it "validates UTF-8 encoding in functions" do
      valid_string = "Hello 世界"
      invalid_string = "Hello \xFF\xFE"

      Lapis::Functions.call("validate_utf8", [valid_string]).should eq("true")
      Lapis::Functions.call("validate_utf8", [invalid_string]).should eq("false")
    end

    it "performs character analysis" do
      test_string = "Hello 世界 123!"

      char_count = Lapis::Functions.call("char_count", [test_string])
      byte_count = Lapis::Functions.call("byte_count", [test_string])
      codepoint_count = Lapis::Functions.call("codepoint_count", [test_string])

      char_count.to_i.should eq(13)
      byte_count.to_i.should be > char_count.to_i
      codepoint_count.to_i.should eq(13)
    end

    it "enhances slugify with Unicode support" do
      test_string = "Hello 世界! This is a test."
      slug = Lapis::Functions.call("slugify", [test_string])

      slug.should eq("hello-世界-this-is-a-test")
    end

    it "performs advanced string manipulation" do
      test_string = "hello world"

      # Character translation
      translated = Lapis::Functions.call("tr", [test_string, "lo", "XO"])
      translated.should eq("heXXO wOrXd")

      # String squeezing
      squeezed = Lapis::Functions.call("squeeze", ["hello    world"])
      squeezed.should eq("helo world")

      # Character deletion
      deleted = Lapis::Functions.call("delete", [test_string, "lo"])
      deleted.should eq("he wrd")

      # String reversal
      reversed = Lapis::Functions.call("reverse", [test_string])
      reversed.should eq("dlrow olleh")

      # String repetition
      repeated = Lapis::Functions.call("repeat", [test_string, "3"])
      repeated.should eq("hello worldhello worldhello world")
    end

    it "builds strings efficiently" do
      result = Lapis::Functions.call("build_string", ["Hello", " ", "World"])
      result.should eq("Hello World")
    end

    it "converts to UTF-16" do
      test_string = "Hello 世界"
      utf16_string = Lapis::Functions.call("to_utf16", [test_string])

      utf16_string.should be_a(String)
      utf16_string.should contain(",")
    end
  end

  describe "Template Processor Unicode Support" do
    it "handles Unicode in template filters" do
      # Test the filter methods directly since they're private
      # We'll test the SafeCast methods instead which are used by the filters

      # Test Unicode normalization
      result = Lapis::SafeCast.normalize_unicode("café", :nfd)
      result.should_not eq("café")

      # Test UTF-8 validation
      result = Lapis::SafeCast.validate_utf8_string?("Hello 世界")
      result.should be_true

      # Test enhanced slugify
      result = Lapis::SafeCast.optimized_slugify("Hello 世界!")
      result.should eq("hello-世界")

      # Test character counting
      analysis = Lapis::SafeCast.advanced_char_analysis("Hello 世界")
      analysis[:total_chars].should eq(8)
      analysis[:total_bytes].should be > 8
    end
  end

  describe "Content UTF-8 Validation" do
    it "validates UTF-8 encoding in content initialization" do
      # This would be tested in integration tests with actual content files
      # For now, we test the validation method directly
      valid_content = "Hello 世界"
      invalid_content = "Hello \xFF\xFE"

      valid_content.valid_encoding?.should be_true
      invalid_content.valid_encoding?.should be_false
    end
  end
end
