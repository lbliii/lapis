require "../spec_helper"
require "../../src/lapis/content"

describe Lapis::Content do
  describe "Reference API Implementation" do
    it "implements custom hash method", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.url = "/test1/"
      content1.title = "Test 1"

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.url = "/test2/"
      content2.title = "Test 2"

      # Hash should be different for different URLs
      content1.hash.should_not eq(content2.hash)

      # Hash should be cached after first call
      first_hash = content1.hash
      second_hash = content1.hash
      first_hash.should eq(second_hash)
    end

    it "implements logical equality", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.url = "/test/"
      content1.title = "Test"

      content2 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content2.url = "/test/"
      content2.title = "Different Title"

      # Should be equal based on URL and file path
      (content1 == content2).should be_true

      # But not same object
      content1.same?(content2).should be_false
    end

    it "implements object identity comparison", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content2 = content1.dup

      # Same object should be same
      content1.same?(content1).should be_true

      # Different objects should not be same
      content1.same?(content2).should be_false
    end

    it "implements optimized dup method", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Original"
      content1.url = "/original/"

      content2 = content1.dup

      # Should be different objects
      content1.same?(content2).should be_false

      # But should have same content
      content2.title.should eq("Original")
      content2.url.should eq("/original/")
    end

    it "implements enhanced inspect method", tags: [TestTags::FAST, TestTags::UNIT] do
      content = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content.title = "Test Post"
      content.url = "/test/"
      content.tags = ["test", "crystal"]

      inspect_output = content.inspect
      inspect_output.should contain("title: \"Test Post\"")
      inspect_output.should contain("url: \"/test/\"")
      inspect_output.should contain("tags: 2")
      inspect_output.should contain("file: test1.md")
    end

    it "provides performance stats", tags: [TestTags::FAST, TestTags::UNIT] do
      content = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")

      stats = content.performance_stats
      stats.should be_a(NamedTuple(hash_cached: Bool, date_cached: Bool, object_id: UInt64))

      # Initially not cached
      stats[:hash_cached].should be_false
      stats[:date_cached].should be_false

      # After hash call, should be cached
      content.hash
      stats = content.performance_stats
      stats[:hash_cached].should be_true
    end
  end

  describe "Optimized Comparison" do
    it "compares content by date first, then title", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Alpha"
      content1.date = Time.utc(2023, 1, 1)

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Beta"
      content2.date = Time.utc(2023, 1, 2)

      # content2 should be "greater" (newer date comes first in our implementation)
      comparison = content1 <=> content2
      comparison.should eq(1)
      comparison = content2 <=> content1
      comparison.should eq(-1)
      comparison = content1 <=> content1
      comparison.should eq(0)
    end

    it "uses title as tiebreaker when dates are equal", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Alpha"
      content1.date = Time.utc(2023, 1, 1)

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Beta"
      content2.date = Time.utc(2023, 1, 1)

      comparison = content1 <=> content2
      comparison.should eq(-1)
      comparison = content2 <=> content1
      comparison.should eq(1)
    end

    it "handles nil dates", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Alpha"
      content1.date = nil

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Beta"
      content2.date = Time.utc(2023, 1, 1)

      # content2 should be "greater" (has a date)
      comparison = content1 <=> content2
      comparison.should eq(1)
      comparison = content2 <=> content1
      comparison.should eq(-1)
    end

    it "supports direct comparison operators", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Alpha"
      content1.date = Time.utc(2023, 1, 1)

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Beta"
      content2.date = Time.utc(2023, 1, 2)

      (content1 < content2).should be_false # content1 is older, so it's "greater" in our sort order
      (content1 > content2).should be_true
      (content1 <= content2).should be_false
      (content1 >= content2).should be_true
      (content1 == content2).should be_false
    end

    it "supports array sorting", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Charlie"
      content1.date = Time.utc(2023, 1, 3)

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Alpha"
      content2.date = Time.utc(2023, 1, 1)

      content3 = Lapis::Content.new("test3.md", {} of String => YAML::Any, "body", "content")
      content3.title = "Beta"
      content3.date = Time.utc(2023, 1, 2)

      content_array = [content1, content2, content3]
      sorted = content_array.sort

      # Should be sorted by date (newest first), then by title
      sorted[0].title.should eq("Charlie") # newest date
      sorted[1].title.should eq("Beta")    # middle date
      sorted[2].title.should eq("Alpha")   # oldest date
    end
  end

  describe "Experimental Reference Features" do
    it "supports unsafe construction from cache", tags: [TestTags::FAST, TestTags::UNIT] do
      cached_data = {
        "title" => "Cached Post",
        "body"  => "Cached content",
        "date"  => "2024-01-15",
      }

      content = Lapis::Content.unsafe_construct_from_cache(cached_data, "cached.md")

      content.title.should eq("Cached Post")
      content.body.should eq("Cached content")
      content.file_path.should eq("cached.md")
    end

    it "supports optimized cloning", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Original"

      # Prime the cache
      content1.hash

      content2 = content1.clone_with_reference_optimization

      # Should be different objects
      content1.same?(content2).should be_false

      # Should have same content
      content2.title.should eq("Original")

      # Cache should be reset
      stats = content2.performance_stats
      stats[:hash_cached].should be_false
    end

    it "supports content sharing", tags: [TestTags::FAST, TestTags::UNIT] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Original"
      content1.body = "Original body"

      content2 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "different", "content")
      content2.title = "Different"

      # Should be able to share content
      result = content1.share_content_with(content2)
      result.should be_true

      # Should now have same body
      content2.body.should eq("Original body")
    end
  end
end
