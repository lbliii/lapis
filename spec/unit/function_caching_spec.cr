require "../spec_helper"

describe "Function Caching" do
  before_each do
    Lapis::Functions.setup
    Lapis::Functions.clear_cache
  end

  it "caches pure function results", tags: [TestTags::FAST, TestTags::UNIT] do
    # Test a pure function (string manipulation)
    result1 = Lapis::Functions.call("upper", ["hello"])
    result2 = Lapis::Functions.call("upper", ["hello"])

    result1.should eq("HELLO")
    result2.should eq("HELLO")

    # Cache should have grown
    stats = Lapis::Functions.cache_stats
    stats["cache_size"].should be > 0
  end

  it "does not cache time-based functions", tags: [TestTags::FAST, TestTags::UNIT] do
    # Test a non-cacheable function (time-based)
    result1 = Lapis::Functions.call("now", [] of String)
    result2 = Lapis::Functions.call("now", [] of String)

    # Both should work but not be cached
    result1.should be_a(String)
    result2.should be_a(String)

    # Cache should remain empty for time functions
    stats = Lapis::Functions.cache_stats
    stats["cache_size"].should eq(0)
  end

  it "manages cache size correctly", tags: [TestTags::FAST, TestTags::UNIT] do
    # Call many different pure functions to test cache management
    10.times do |i|
      Lapis::Functions.call("upper", ["test#{i}"])
    end

    stats = Lapis::Functions.cache_stats
    stats["cache_size"].should be > 0
    stats["max_cache_size"].should eq(1000)
  end

  it "clears cache when requested", tags: [TestTags::FAST, TestTags::UNIT] do
    # Add something to cache
    Lapis::Functions.call("upper", ["test"])

    stats = Lapis::Functions.cache_stats
    stats["cache_size"].should be > 0

    # Clear cache
    Lapis::Functions.clear_cache

    stats = Lapis::Functions.cache_stats
    stats["cache_size"].should eq(0)
  end
end
