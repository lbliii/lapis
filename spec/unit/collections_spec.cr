require "../spec_helper"

describe Lapis::ContentCollections do
  describe "#initialize" do
    it "creates default collections", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
        TestDataFactory.create_content_item("About", "", ["info"], "pages"),
        TestDataFactory.create_content_item("Contact", "", ["info"], "pages"),
      ]

      collections = Lapis::ContentCollections.new(content)

      collections.get_collection("posts").should_not be_nil
      collections.get_collection("pages").should_not be_nil
      collections.get_collection("all").should_not be_nil
      collections.get_collection("sections").should_not be_nil

      collections.get_collection("posts").not_nil!.size.should eq(2)
      collections.get_collection("pages").not_nil!.size.should eq(2)
      collections.get_collection("all").not_nil!.size.should eq(4)
    end
  end

  describe "Iterable integration" do
    it "Collection includes Iterable module", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [TestDataFactory.create_content_item("Test Post", "2024-01-15", ["test"], "posts")]
      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # Test that Collection includes Iterable
      collection.should be_a(Iterable(Lapis::Content))
    end

    it "Collection.each returns iterator", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
      ]
      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      iterator = collection.each
      iterator.should be_a(Iterator(Lapis::Content))

      items = iterator.to_a
      items.size.should eq(2)
      items.first.title.should eq("Post 1")
      items.last.title.should eq("Post 2")
    end
  end

  describe "Advanced iteration methods" do
    it "paginated_content works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..10).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # Test pagination
      page1 = collection.paginated_content(3, 1)
      page1.size.should eq(3)
      page1.first.title.should eq("Post 1")

      page2 = collection.paginated_content(3, 2)
      page2.size.should eq(3)
      page2.first.title.should eq("Post 4")

      page4 = collection.paginated_content(3, 4)
      page4.size.should eq(1)
      page4.first.title.should eq("Post 10")

      # Test out of bounds
      empty_page = collection.paginated_content(3, 5)
      empty_page.should be_empty
    end

    it "group_by_date works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-15", ["crystal"], "posts"),
        TestDataFactory.create_content_item("Post 3", "2024-01-16", ["test"], "posts"),
      ]

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      grouped = collection.group_by_date
      grouped.keys.should contain("2024-01-15 00:00:00 UTC")
      grouped.keys.should contain("2024-01-16 00:00:00 UTC")
      grouped["2024-01-15 00:00:00 UTC"].size.should eq(2)
      grouped["2024-01-16 00:00:00 UTC"].size.should eq(1)
    end

    it "content_previews works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..5).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      previews = collection.content_previews(3)
      previews.size.should eq(3) # 5 items with window size 3 = 3 windows

      previews[0].size.should eq(3)
      previews[0].first.title.should eq("Post 1")
      previews[0].last.title.should eq("Post 3")

      previews[1].size.should eq(3)
      previews[1].first.title.should eq("Post 2")
      previews[1].last.title.should eq("Post 4")

      previews[2].size.should eq(3)
      previews[2].first.title.should eq("Post 3")
      previews[2].last.title.should eq("Post 5")
    end

    it "group_by_section_changes works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
        TestDataFactory.create_content_item("About", "", ["info"], "pages"),
        TestDataFactory.create_content_item("Contact", "", ["info"], "pages"),
        TestDataFactory.create_content_item("Post 3", "2024-01-17", ["test"], "posts"),
      ]

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("all").not_nil!

      groups = collection.group_by_section_changes
      groups.size.should eq(3) # posts, pages, posts

      groups[0].size.should eq(2) # posts
      groups[0].all?(&.section.==("posts")).should be_true

      groups[1].size.should eq(2) # pages
      groups[1].all?(&.section.==("pages")).should be_true

      groups[2].size.should eq(1) # posts again
      groups[2].all?(&.section.==("posts")).should be_true
    end

    it "recent_with_index works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..10).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      recent = collection.recent_with_index(3)
      recent.size.should eq(3)

      recent[0].should eq({collection.content[0], 0})
      recent[1].should eq({collection.content[1], 1})
      recent[2].should eq({collection.content[2], 2})
    end
  end

  describe "ContentCollections advanced methods" do
    it "paginated works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..10).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)

      page1 = collections.paginated("posts", 3, 1)
      page1.size.should eq(3)
      page1.first.title.should eq("Post 1")

      page2 = collections.paginated("posts", 3, 2)
      page2.size.should eq(3)
      page2.first.title.should eq("Post 4")
    end

    it "grouped_by_date works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-15", ["crystal"], "posts"),
        TestDataFactory.create_content_item("Post 3", "2024-01-16", ["test"], "posts"),
      ]

      collections = Lapis::ContentCollections.new(content)
      grouped = collections.grouped_by_date("posts")

      grouped.keys.should contain("2024-01-15 00:00:00 UTC")
      grouped.keys.should contain("2024-01-16 00:00:00 UTC")
      grouped["2024-01-15 00:00:00 UTC"].size.should eq(2)
      grouped["2024-01-16 00:00:00 UTC"].size.should eq(1)
    end

    it "content_sliding_window works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..5).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)
      windows = collections.content_sliding_window("posts", 3)

      windows.size.should eq(3)
      windows[0].size.should eq(3)
      windows[0].first.title.should eq("Post 1")
      windows[0].last.title.should eq("Post 3")
    end

    it "section_groups works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
        TestDataFactory.create_content_item("About", "", ["info"], "pages"),
        TestDataFactory.create_content_item("Contact", "", ["info"], "pages"),
      ]

      collections = Lapis::ContentCollections.new(content)
      groups = collections.section_groups("all")

      groups.size.should eq(2) # posts, pages
      groups[0].all?(&.section.==("posts")).should be_true
      groups[1].all?(&.section.==("pages")).should be_true
    end

    it "recent_with_positions works correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..10).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      collections = Lapis::ContentCollections.new(content)
      recent = collections.recent_with_positions("posts", 3)

      recent.size.should eq(3)
      recent[0][0].title.should eq("Post 1")
      recent[0][1].should eq(0)
      recent[1][0].title.should eq("Post 2")
      recent[1][1].should eq(1)
    end
  end

  describe "Performance Optimization Features" do
    it "provides O(1) URL lookups", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
      ]
      content[0].url = "/post-1/"
      content[1].url = "/post-2/"

      collections = Lapis::ContentCollections.new(content)

      # O(1) lookup by URL
      found = collections.find_by_url("/post-1/")
      found.should_not be_nil
      found.not_nil!.title.should eq("Post 1")

      # Should return nil for non-existent URL
      not_found = collections.find_by_url("/nonexistent/")
      not_found.should be_nil
    end

    it "provides O(1) object_id lookups", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
      ]

      collections = Lapis::ContentCollections.new(content)
      object_id = content[0].object_id

      # O(1) lookup by object_id
      found = collections.find_by_object_id(object_id)
      found.should_not be_nil
      found.not_nil!.title.should eq("Post 1")

      # Should return nil for non-existent object_id
      not_found = collections.find_by_object_id(999999999)
      not_found.should be_nil
    end

    it "provides performance statistics", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
      ]

      collections = Lapis::ContentCollections.new(content)

      # Perform some operations
      collections.find_by_url("/post-1/")
      collections.find_by_object_id(content[0].object_id)
      collections.where("posts", draft: false)

      stats = collections.performance_stats
      stats.should be_a(Hash(String, Int32))
      stats["url_lookup"].should eq(1)
      stats["object_id_lookup"].should eq(1)
      stats["where_posts"].should eq(1)
    end

    it "supports performance stats reset", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts")]
      collections = Lapis::ContentCollections.new(content)

      # Perform operation
      collections.find_by_url("/post-1/")

      # Check stats
      stats = collections.performance_stats
      stats["url_lookup"].should eq(1)

      # Reset stats
      collections.reset_performance_stats
      # Check stats are reset
      stats = collections.performance_stats
      stats["url_lookup"].should eq(0)
    end
  end

  describe "Collection Performance Features" do
    it "provides O(1) URL lookups in collections", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
      ]
      content[0].url = "/post-1/"
      content[1].url = "/post-2/"

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # O(1) lookup by URL
      found = collection.find_by_url("/post-1/")
      found.should_not be_nil
      found.not_nil!.title.should eq("Post 1")
    end

    it "supports deduplication by identity", tags: [TestTags::FAST, TestTags::UNIT] do
      # Create actual duplicate objects (same reference)
      content_item = TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts")
      content = [
        content_item,
        content_item, # Same object reference - true duplicate
      ]

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # Should have 2 items initially
      collection.size.should eq(2)

      # Deduplicate by identity
      deduplicated = collection.deduplicate_by_identity
      deduplicated.size.should eq(1) # Should remove duplicate
    end

    it "supports deduplication by URL", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [
        TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts"),
        TestDataFactory.create_content_item("Post 2", "2024-01-16", ["crystal"], "posts"),
      ]
      content[0].url = "/same-url/"
      content[1].url = "/same-url/" # Same URL

      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # Should have 2 items initially
      collection.size.should eq(2)

      # Deduplicate by URL
      deduplicated = collection.deduplicate_by_url
      deduplicated.size.should eq(1) # Should remove duplicate
    end

    it "provides collection performance statistics", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts")]
      collections = Lapis::ContentCollections.new(content)
      collection = collections.get_collection("posts").not_nil!

      # Perform operations
      collection.find_by_url("/post-1/")
      collection.deduplicate_by_identity

      stats = collection.performance_stats
      stats.should be_a(Hash(String, Int32))
      stats["url_lookup"].should eq(1)
      stats["deduplicate_identity"].should eq(1)
    end
  end

  describe "Edge cases" do
    it "handles empty collections gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      collections = Lapis::ContentCollections.new([] of Lapis::Content)

      collections.paginated("posts", 3, 1).should be_empty
      collections.grouped_by_date("posts").should be_empty
      collections.content_sliding_window("posts", 3).should be_empty
      collections.section_groups("posts").should be_empty
      collections.recent_with_positions("posts", 3).should be_empty
    end

    it "handles non-existent collections gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      content = [TestDataFactory.create_content_item("Post 1", "2024-01-15", ["test"], "posts")]
      collections = Lapis::ContentCollections.new(content)

      collections.paginated("nonexistent", 3, 1).should be_empty
      collections.grouped_by_date("nonexistent").should be_empty
      collections.content_sliding_window("nonexistent", 3).should be_empty
      collections.section_groups("nonexistent").should be_empty
      collections.recent_with_positions("nonexistent", 3).should be_empty
    end
  end
end
