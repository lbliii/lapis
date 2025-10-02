require "../spec_helper"

describe Lapis::ArrayFunctions do
  before_each do
    Lapis::Functions.setup
  end

  describe "Basic array operations" do
    it "len function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("len", ["hello"])
      result.should eq("5")
    end

    it "uniq function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("uniq", ["a,b,a,c,b"])
      result.should eq("a,b,c")
    end

    it "sample function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("sample", ["a,b,c,d", "2"])
      result.split(",").size.should eq(2)
    end

    it "shuffle function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("shuffle", ["a,b,c"])
      result.split(",").size.should eq(3)
    end

    it "rotate function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("rotate", ["a,b,c,d", "1"])
      result.should eq("b,c,d,a")
    end
  end

  describe "Array manipulation functions" do
    it "sort_by_length function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("sort_by_length", ["a,hello,hi", "false"])
      result.should eq("a,hi,hello")
    end

    it "partition function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("partition", ["short,verylong,medium", "length"])
      result.should contain("long:")
      result.should contain("short:")
    end

    it "compact function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("compact", ["a,,b,c,"])
      result.should eq("a,,b,c,") # compact only removes nil, not empty strings
    end

    it "chunk function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("chunk", ["a,aa,aaa,b,bb", "length"])
      result.should contain("1:")
      result.should contain("2:")
      result.should contain("3:")
    end
  end

  describe "Array search functions" do
    it "index function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("index", ["a,b,c,d", "c"])
      result.should eq("2")

      result = Lapis::Functions.call("index", ["a,b,c,d", "x"])
      result.should eq("-1")
    end

    it "rindex function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("rindex", ["a,b,c,b", "b"])
      result.should eq("3")
    end
  end

  describe "Array slicing functions" do
    it "array_truncate function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("array_truncate", ["a,b,c,d,e", "1", "4"])
      result.should eq("b,c,d")
    end

    it "array_truncate handles edge cases", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("array_truncate", ["a,b,c", "5", "10"])
      result.should eq("")
    end
  end

  describe "Edge cases" do
    it "handles empty arrays", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("uniq", [""])
      result.should eq("")

      result = Lapis::Functions.call("sample", ["", "1"])
      result.should eq("")
    end

    it "handles single element arrays", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("uniq", ["a"])
      result.should eq("a")

      result = Lapis::Functions.call("shuffle", ["a"])
      result.should eq("a")
    end
  end
end
