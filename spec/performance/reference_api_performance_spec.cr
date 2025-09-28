require "../spec_helper"
require "../../src/lapis/content"
require "../../src/lapis/collections"

describe "Reference API Performance Benchmarks" do
  describe "Content Hash Performance" do
    it "benchmarks hash performance", tags: [TestTags::PERFORMANCE] do
      content = Lapis::Content.new("test.md", {} of String => YAML::Any, "body", "content")
      content.url = "/test/"
      content.title = "Test Post"

      # Benchmark hash computation
      start_time = Time.utc
      1000.times do
        content.hash
      end
      duration = Time.utc - start_time

      # Should be fast (less than 1ms for 1000 operations)
      duration.total_milliseconds.should be < 1.0
    end

    it "benchmarks hash caching", tags: [TestTags::PERFORMANCE] do
      content = Lapis::Content.new("test.md", {} of String => YAML::Any, "body", "content")
      content.url = "/test/"
      content.title = "Test Post"

      # First hash call (uncached)
      start_time = Time.utc
      first_hash = content.hash
      first_duration = Time.utc - start_time

      # Second hash call (cached)
      start_time = Time.utc
      second_hash = content.hash
      second_duration = Time.utc - start_time

      # Hashes should be equal
      first_hash.should eq(second_hash)

      # Cached call should be faster
      second_duration.should be < first_duration
    end
  end

  describe "Collection Lookup Performance" do
    it "benchmarks O(1) URL lookups", tags: [TestTags::PERFORMANCE] do
      # Create large collection
      content = (1..1000).map do |i|
        item = TestDataFactory.create_content_item("Post #{i}", "2024-01-15", ["test"], "posts")
        item.url = "/post-#{i}/"
        item
      end

      collections = Lapis::ContentCollections.new(content)

      # Benchmark URL lookup
      start_time = Time.utc
      1000.times do |i|
        collections.find_by_url("/post-#{i + 1}/")
      end
      duration = Time.utc - start_time

      # Should be fast (less than 10ms for 1000 O(1) lookups)
      duration.total_milliseconds.should be < 10.0
    end

    it "benchmarks O(1) object_id lookups", tags: [TestTags::PERFORMANCE] do
      # Create large collection
      content = (1..1000).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-15", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)
      object_ids = content.map(&.object_id)

      # Benchmark object_id lookup
      start_time = Time.utc
      1000.times do |i|
        collections.find_by_object_id(object_ids[i])
      end
      duration = Time.utc - start_time

      # Should be fast (less than 10ms for 1000 O(1) lookups)
      duration.total_milliseconds.should be < 10.0
    end
  end

  describe "Comparison Performance" do
    it "benchmarks content comparison", tags: [TestTags::PERFORMANCE] do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Alpha"
      content1.date = Time.utc(2023, 1, 1)

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Beta"
      content2.date = Time.utc(2023, 1, 2)

      # Benchmark comparison
      start_time = Time.utc
      1000.times do
        content1 <=> content2
      end
      duration = Time.utc - start_time

      # Should be fast (less than 1ms for 1000 comparisons)
      duration.total_milliseconds.should be < 1.0
    end

    it "benchmarks array sorting performance", tags: [TestTags::PERFORMANCE] do
      # Create large array of content
      content_array = (1..1000).map do |i|
        item = Lapis::Content.new("test#{i}.md", {} of String => YAML::Any, "body", "content")
        item.title = "Post #{i}"
        item.date = Time.utc(2023, 1, i % 30 + 1)
        item
      end

      # Benchmark sorting
      start_time = Time.utc
      sorted = content_array.sort
      duration = Time.utc - start_time

      # Should be fast (less than 50ms for 1000 items)
      duration.total_milliseconds.should be < 50.0

      # Should be properly sorted
      sorted.first.date.should be >= sorted.last.date
    end
  end

  describe "Deduplication Performance" do
    it "benchmarks identity deduplication", tags: [TestTags::PERFORMANCE] do
      # Create collection with duplicates
      base_content = TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts")
      content = [base_content] * 1000 # 1000 duplicates

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # Benchmark deduplication
      start_time = Time.utc
      deduplicated = collection.deduplicate_by_identity
      duration = Time.utc - start_time

      # Should be fast (less than 10ms for 1000 items)
      duration.total_milliseconds.should be < 10.0

      # Should remove duplicates
      deduplicated.size.should eq(1)
    end

    it "benchmarks URL deduplication", tags: [TestTags::PERFORMANCE] do
      # Create collection with URL duplicates
      content = (1..1000).map do |i|
        item = TestDataFactory.create_content_item("Post #{i}", "2024-01-15", ["test"], "posts")
        item.url = "/same-url/" # All same URL
        item
      end

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # Benchmark deduplication
      start_time = Time.utc
      deduplicated = collection.deduplicate_by_url
      duration = Time.utc - start_time

      # Should be fast (less than 10ms for 1000 items)
      duration.total_milliseconds.should be < 10.0

      # Should remove duplicates
      deduplicated.size.should eq(1)
    end
  end

  describe "Memory Usage Performance" do
    it "benchmarks memory efficiency", tags: [TestTags::PERFORMANCE] do
      # Create large collection
      content = (1..1000).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-15", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)

      # Get initial memory usage
      initial_stats = collections.performance_stats

      # Perform operations
      100.times do
        collections.find_by_url("/post-1/")
        collections.where("posts", draft: false)
        collections.sort_by("posts", "date")
      end

      # Get final stats
      final_stats = collections.performance_stats

      # Should have tracked operations
      final_stats["url_lookup"].should eq(100)
      final_stats["where_posts"].should eq(100)
      final_stats["sort_by_date"].should eq(100)
    end
  end
end
