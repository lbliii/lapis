require "../spec_helper"
require "../../src/lapis/safe_cast"

describe Lapis::SafeCast do
  describe "Character validation methods using Char API" do
    describe "numeric_string?" do
      it "returns true for strings containing only digits", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.numeric_string?("12345").should be_true
        Lapis::SafeCast.numeric_string?("0").should be_true
        Lapis::SafeCast.numeric_string?("999").should be_true
      end

      it "returns false for strings containing non-digits", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.numeric_string?("hello123").should be_false
        Lapis::SafeCast.numeric_string?("123abc").should be_false
        Lapis::SafeCast.numeric_string?("12.34").should be_false
        Lapis::SafeCast.numeric_string?("").should be_false
      end
    end

    describe "alphabetic_string?" do
      it "returns true for strings containing only letters", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.alphabetic_string?("Hello").should be_true
        Lapis::SafeCast.alphabetic_string?("WORLD").should be_true
        Lapis::SafeCast.alphabetic_string?("crystal").should be_true
      end

      it "returns false for strings containing non-letters", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.alphabetic_string?("Hello123").should be_false
        Lapis::SafeCast.alphabetic_string?("123").should be_false
        Lapis::SafeCast.alphabetic_string?("hello world").should be_false
        Lapis::SafeCast.alphabetic_string?("").should be_false
      end
    end

    describe "alphanumeric_string?" do
      it "returns true for strings containing only letters and digits", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.alphanumeric_string?("Hello123").should be_true
        Lapis::SafeCast.alphanumeric_string?("ABC123").should be_true
        Lapis::SafeCast.alphanumeric_string?("123abc").should be_true
      end

      it "returns false for strings containing other characters", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.alphanumeric_string?("Hello World").should be_false
        Lapis::SafeCast.alphanumeric_string?("hello-world").should be_false
        Lapis::SafeCast.alphanumeric_string?("test@example.com").should be_false
        Lapis::SafeCast.alphanumeric_string?("").should be_false
      end
    end

    describe "valid_identifier?" do
      it "returns true for valid identifiers", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.valid_identifier?("valid_identifier").should be_true
        Lapis::SafeCast.valid_identifier?("_private").should be_true
        Lapis::SafeCast.valid_identifier?("CamelCase").should be_true
        Lapis::SafeCast.valid_identifier?("var123").should be_true
      end

      it "returns false for invalid identifiers", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.valid_identifier?("123invalid").should be_false
        Lapis::SafeCast.valid_identifier?("invalid-name").should be_false
        Lapis::SafeCast.valid_identifier?("invalid.name").should be_false
        Lapis::SafeCast.valid_identifier?("").should be_false
      end
    end

    describe "whitespace_string?" do
      it "returns true for strings containing only whitespace", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.whitespace_string?("   ").should be_true
        Lapis::SafeCast.whitespace_string?("\t\n").should be_true
        Lapis::SafeCast.whitespace_string?("").should be_true
      end

      it "returns false for strings containing non-whitespace", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.whitespace_string?("hello").should be_false
        Lapis::SafeCast.whitespace_string?("  hello  ").should be_false
      end
    end
  end

  describe "Character extraction methods using Char API" do
    describe "extract_digits" do
      it "extracts only digits from strings", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.extract_digits("abc123def456").should eq("123456")
        Lapis::SafeCast.extract_digits("hello").should eq("")
        Lapis::SafeCast.extract_digits("12345").should eq("12345")
      end
    end

    describe "extract_letters" do
      it "extracts only letters from strings", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.extract_letters("abc123def456").should eq("abcdef")
        Lapis::SafeCast.extract_letters("12345").should eq("")
        Lapis::SafeCast.extract_letters("Hello World").should eq("HelloWorld")
      end
    end

    describe "capitalize_first" do
      it "capitalizes the first character", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.capitalize_first("hello world").should eq("Hello world")
        Lapis::SafeCast.capitalize_first("HELLO").should eq("HELLO")
        Lapis::SafeCast.capitalize_first("").should eq("")
      end
    end
  end

  describe "Character counting methods using Char API" do
    describe "count_uppercase" do
      it "counts uppercase letters", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.count_uppercase("Hello World 123").should eq(2)
        Lapis::SafeCast.count_uppercase("HELLO").should eq(5)
        Lapis::SafeCast.count_uppercase("hello").should eq(0)
      end
    end

    describe "count_lowercase" do
      it "counts lowercase letters", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.count_lowercase("Hello World 123").should eq(8)
        Lapis::SafeCast.count_lowercase("HELLO").should eq(0)
        Lapis::SafeCast.count_lowercase("hello").should eq(5)
      end
    end

    describe "starts_with_uppercase?" do
      it "checks if string starts with uppercase letter", tags: [TestTags::FAST, TestTags::UNIT] do
        Lapis::SafeCast.starts_with_uppercase?("Hello World").should be_true
        Lapis::SafeCast.starts_with_uppercase?("HELLO").should be_true
        Lapis::SafeCast.starts_with_uppercase?("hello world").should be_false
        Lapis::SafeCast.starts_with_uppercase?("").should be_false
      end
    end
  end

  describe "Symbol validation using Char API" do
    describe "valid_symbol?" do
      it "validates symbols using Char API instead of regex", tags: [TestTags::FAST, TestTags::UNIT] do
        # Valid symbols
        Lapis::SafeCast.valid_symbol?("valid_symbol").should be_true
        Lapis::SafeCast.valid_symbol?("_private").should be_true
        Lapis::SafeCast.valid_symbol?("CamelCase").should be_true
        Lapis::SafeCast.valid_symbol?("var123").should be_true

        # Invalid symbols
        Lapis::SafeCast.valid_symbol?("123invalid").should be_false
        Lapis::SafeCast.valid_symbol?("invalid-name").should be_false
        Lapis::SafeCast.valid_symbol?("invalid.name").should be_false
        Lapis::SafeCast.valid_symbol?("").should be_false
      end
    end
  end

  describe "Existing functionality compatibility" do
    it "maintains existing casting functionality", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that existing methods still work
      result = Lapis::SafeCast.cast_or_nil("hello", String)
      result.should eq("hello")

      result = Lapis::SafeCast.cast_or_default("world", String, "default")
      result.should eq("world")
    end
  end
end
