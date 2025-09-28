require "../spec_helper"

describe Lapis::Paginator do
  describe "#current_items" do
    it "uses each_slice for pagination", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..10).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      paginator = Lapis::Paginator.new(content, 3, 1)
      page1 = paginator.current_items
      page1.size.should eq(3)
      page1.first.title.should eq("Post 1")
      page1.last.title.should eq("Post 3")

      paginator = Lapis::Paginator.new(content, 3, 2)
      page2 = paginator.current_items
      page2.size.should eq(3)
      page2.first.title.should eq("Post 4")
      page2.last.title.should eq("Post 6")

      paginator = Lapis::Paginator.new(content, 3, 4)
      page4 = paginator.current_items
      page4.size.should eq(1)
      page4.first.title.should eq("Post 10")
    end

    it "handles empty content gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      paginator = Lapis::Paginator.new([] of Lapis::Content, 3, 1)
      paginator.current_items.should be_empty
    end

    it "handles out of bounds pages gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..5).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      paginator = Lapis::Paginator.new(content, 3, 10) # Page 10 doesn't exist
      paginator.current_items.should be_empty
    end
  end

  describe "#page_numbers" do
    it "uses each_with_index for page generation", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..25).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      paginator = Lapis::Paginator.new(content, 5, 3) # Page 3 of 5
      pages = paginator.page_numbers(5)

      pages.size.should be > 0
      pages.any?(&.current).should be_true

      # Find current page
      current_page = pages.find(&.current)
      current_page.should_not be_nil
      current_page.not_nil!.number.should eq(3)
    end
  end

  describe "#generate_paginated_archives" do
    it "uses each_with_index for archive generation", tags: [TestTags::INTEGRATION] do
      content = (1..15).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir
        config.output_dir = File.join(temp_dir, "output")

        generator = Lapis::PaginationGenerator.new(config)

        # This should not raise an error and should process all pages
        generator.generate_paginated_archives(content, 5)
      end
    end
  end

  describe "#generate_tag_paginated_archives" do
    it "uses each_with_index for tag archive generation", tags: [TestTags::INTEGRATION] do
      posts_by_tag = {
        "crystal" => (1..8).map do |i|
          TestDataFactory.create_content_item("Crystal Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["crystal"], "posts")
        end,
        "lapis" => (1..12).map do |i|
          TestDataFactory.create_content_item("Lapis Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["lapis"], "posts")
        end,
      }

      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.root_dir = temp_dir
        config.output_dir = File.join(temp_dir, "output")

        generator = Lapis::PaginationGenerator.new(config)

        # This should not raise an error and should process all tag pages
        generator.generate_tag_paginated_archives(posts_by_tag, 5)
      end
    end
  end

  describe "Error handling" do
    it "handles zero per_page gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..5).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      paginator = Lapis::Paginator.new(content, 0, 1)
      paginator.current_items.should be_empty
    end

    it "handles negative page numbers gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..5).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      paginator = Lapis::Paginator.new(content, 3, -1)
      paginator.current_items.should be_empty
    end

    it "handles large page numbers gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      content = (1..5).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-#{i.to_s.rjust(2, '0')}", ["test"], "posts")
      end

      paginator = Lapis::Paginator.new(content, 3, 1000)
      paginator.current_items.should be_empty
    end
  end

  describe "Performance with Iterable methods" do
    it "handles large datasets efficiently", tags: [TestTags::PERFORMANCE] do
      content = (1..1000).map do |i|
        TestDataFactory.create_content_item("Post #{i}", "2024-01-15", ["test"], "posts")
      end

      paginator = Lapis::Paginator.new(content, 10, 50)

      # Should be fast even with large datasets
      start_time = Time.monotonic
      items = paginator.current_items
      end_time = Time.monotonic

      items.size.should eq(10)
      items.first.title.should eq("Post 491")
      items.last.title.should eq("Post 500")

      # Should complete quickly (less than 100ms for this operation)
      (end_time - start_time).total_milliseconds.should be < 100
    end
  end
end
