require "../spec_helper"
require "../../src/lapis/content"
require "../../src/lapis/content_comparison"

describe Lapis::ContentComparison do
  describe ".compare_values" do
    it "compares Time objects" do
      time1 = Time.utc(2023, 1, 1)
      time2 = Time.utc(2023, 1, 2)

      Lapis::ContentComparison.compare_values(time1, time2).should eq(-1)
      Lapis::ContentComparison.compare_values(time2, time1).should eq(1)
      Lapis::ContentComparison.compare_values(time1, time1).should eq(0)
    end

    it "compares String objects" do
      Lapis::ContentComparison.compare_values("apple", "banana").should eq(-1)
      Lapis::ContentComparison.compare_values("banana", "apple").should eq(1)
      Lapis::ContentComparison.compare_values("apple", "apple").should eq(0)
    end

    it "compares Number objects" do
      Lapis::ContentComparison.compare_values(1, 2).should eq(-1)
      Lapis::ContentComparison.compare_values(2, 1).should eq(1)
      Lapis::ContentComparison.compare_values(1, 1).should eq(0)
    end

    it "handles nil values" do
      Lapis::ContentComparison.compare_values(nil, nil).should eq(0)
      Lapis::ContentComparison.compare_values(nil, "test").should eq(-1)
      Lapis::ContentComparison.compare_values("test", nil).should eq(1)
    end

    it "falls back to string comparison for unknown types" do
      Lapis::ContentComparison.compare_values(true, false).should eq(1) # "true" > "false"
    end
  end

  describe ".compare_by_property" do
    it "compares content by title" do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Apple"

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Banana"

      Lapis::ContentComparison.compare_by_property(content1, content2, "title").should eq(-1)
      Lapis::ContentComparison.compare_by_property(content2, content1, "title").should eq(1)
    end

    it "compares content by date" do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.date = Time.utc(2023, 1, 1)

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.date = Time.utc(2023, 1, 2)

      Lapis::ContentComparison.compare_by_property(content1, content2, "date").should eq(-1)
      Lapis::ContentComparison.compare_by_property(content2, content1, "date").should eq(1)
    end

    it "handles nil dates" do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.date = nil

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.date = Time.utc(2023, 1, 1)

      Lapis::ContentComparison.compare_by_property(content1, content2, "date").should eq(-1)
      Lapis::ContentComparison.compare_by_property(content2, content1, "date").should eq(1)
    end
  end

  describe ".sort_by_property" do
    it "sorts content by title" do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Charlie"

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Alpha"

      content3 = Lapis::Content.new("test3.md", {} of String => YAML::Any, "body", "content")
      content3.title = "Beta"

      content_array = [content1, content2, content3]
      sorted = Lapis::ContentComparison.sort_by_property(content_array, "title")

      sorted[0].title.should eq("Alpha")
      sorted[1].title.should eq("Beta")
      sorted[2].title.should eq("Charlie")
    end

    it "sorts content by date" do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.date = Time.utc(2023, 1, 3)

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.date = Time.utc(2023, 1, 1)

      content3 = Lapis::Content.new("test3.md", {} of String => YAML::Any, "body", "content")
      content3.date = Time.utc(2023, 1, 2)

      content_array = [content1, content2, content3]
      sorted = Lapis::ContentComparison.sort_by_property(content_array, "date")

      sorted[0].date.should eq(Time.utc(2023, 1, 1))
      sorted[1].date.should eq(Time.utc(2023, 1, 2))
      sorted[2].date.should eq(Time.utc(2023, 1, 3))
    end

    it "supports reverse sorting" do
      content1 = Lapis::Content.new("test1.md", {} of String => YAML::Any, "body", "content")
      content1.title = "Alpha"

      content2 = Lapis::Content.new("test2.md", {} of String => YAML::Any, "body", "content")
      content2.title = "Beta"

      content_array = [content1, content2]
      sorted = Lapis::ContentComparison.sort_by_property(content_array, "title", reverse: true)

      sorted[0].title.should eq("Beta")
      sorted[1].title.should eq("Alpha")
    end
  end
end

describe Lapis::Content do
  describe "Comparable implementation" do
    it "compares content by date first, then title" do
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

    it "uses title as tiebreaker when dates are equal" do
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

    it "handles nil dates" do
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

    it "supports direct comparison operators" do
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

    it "supports array sorting" do
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
end
