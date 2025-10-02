require "../spec_helper"

describe Lapis::MathFunctions do
  before_each do
    Lapis::Functions.setup
  end

  describe "Basic arithmetic operations" do
    it "add function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("add", ["2", "3"])
      result.should eq("5.0")
    end

    it "subtract function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("subtract", ["10", "3"])
      result.should eq("7.0")
    end

    it "multiply function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("multiply", ["4", "5"])
      result.should eq("20.0")
    end

    it "divide function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("divide", ["15", "3"])
      result.should eq("5.0")
    end

    it "modulo function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("modulo", ["10", "3"])
      result.should eq("1")
    end
  end

  describe "Mathematical functions" do
    it "round function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("round", ["3.14159", "0"])
      result.should eq("3.0")

      result = Lapis::Functions.call("round", ["3.14159", "2"])
      result.should eq("3.14")
    end

    it "ceil function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("ceil", ["3.1"])
      result.should eq("4.0")
    end

    it "floor function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("floor", ["3.9"])
      result.should eq("3.0")
    end

    it "abs function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("abs", ["-5"])
      result.should eq("5.0")
    end

    it "sqrt function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("sqrt", ["16"])
      result.should eq("4.0")
    end

    it "pow function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("pow", ["2", "3"])
      result.should eq("8.0")
    end
  end

  describe "Aggregate functions" do
    it "min function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("min", ["5", "3", "8", "1"])
      result.should eq("1.0")
    end

    it "max function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("max", ["5", "3", "8", "1"])
      result.should eq("8.0")
    end

    it "sum function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("sum", ["1", "2", "3", "4"])
      result.should eq("10.0")
    end
  end

  describe "Error handling" do
    it "handles division by zero", tags: [TestTags::FAST, TestTags::UNIT] do
      expect_raises(ArgumentError, "divide by zero") do
        Lapis::Functions.call("divide", ["5", "0"])
      end
    end

    it "handles invalid numeric arguments", tags: [TestTags::FAST, TestTags::UNIT] do
      expect_raises(ArgumentError, "add arguments must be numeric") do
        Lapis::Functions.call("add", ["hello", "world"])
      end
    end

    it "handles sqrt of negative number", tags: [TestTags::FAST, TestTags::UNIT] do
      expect_raises(ArgumentError, "sqrt of negative number") do
        Lapis::Functions.call("sqrt", ["-4"])
      end
    end
  end
end
