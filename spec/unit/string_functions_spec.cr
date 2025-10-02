require "../spec_helper"

describe Lapis::StringFunctions do
  before_each do
    Lapis::Functions.setup
  end

  describe "Basic string manipulation" do
    it "uppercase function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("upper", ["hello"])
      result.should eq("HELLO")
    end

    it "lowercase function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("lower", ["WORLD"])
      result.should eq("world")
    end

    it "title case function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("title", ["hello world"])
      result.should eq("Hello World")
    end

    it "trim function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("trim", ["  hello  "])
      result.should eq("hello")
    end
  end

  describe "Advanced string operations" do
    it "slugify function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("slugify", ["Hello World!"])
      result.should eq("hello-world")
    end

    it "camelize function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("camelize", ["hello-world"])
      result.should eq("HelloWorld")
    end

    it "underscore function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("underscore", ["HelloWorld"])
      result.should eq("hello_world")
    end

    it "dasherize function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("dasherize", ["hello_world"])
      result.should eq("hello-world")
    end
  end

  describe "Character analysis functions" do
    it "char_count function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("char_count", ["hello"])
      result.should eq("5")
    end

    it "char_count_alpha function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("char_count_alpha", ["hello123"])
      result.should eq("5")
    end

    it "char_count_digit function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("char_count_digit", ["hello123"])
      result.should eq("3")
    end

    it "extract_digits function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("extract_digits", ["hello123world"])
      result.should eq("123")
    end

    it "extract_letters function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("extract_letters", ["hello123world"])
      result.should eq("helloworld")
    end
  end

  describe "String validation functions" do
    it "is_numeric function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("is_numeric", ["123"])
      result.should eq("true")

      result = Lapis::Functions.call("is_numeric", ["hello"])
      result.should eq("false")
    end

    it "is_alpha function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("is_alpha", ["hello"])
      result.should eq("true")

      result = Lapis::Functions.call("is_alpha", ["hello123"])
      result.should eq("false")
    end

    it "is_alphanumeric function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("is_alphanumeric", ["hello123"])
      result.should eq("true")

      result = Lapis::Functions.call("is_alphanumeric", ["hello!"])
      result.should eq("false")
    end
  end

  describe "Text processing functions" do
    it "truncate function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("truncate", ["This is a long string", "10", "..."])
      result.should eq("This is...")
    end

    it "truncatewords function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("truncatewords", ["This is a long string with many words", "3", "..."])
      result.should eq("This is a...")
    end

    it "pluralize function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("pluralize", ["cat", "1"])
      result.should eq("cat")

      result = Lapis::Functions.call("pluralize", ["cat", "2"])
      result.should eq("cats")
    end

    it "singularize function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("singularize", ["cats"])
      result.should eq("cat")

      result = Lapis::Functions.call("singularize", ["cat"])
      result.should eq("cat")
    end
  end
end
