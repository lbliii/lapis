require "./logger"

module Lapis
  # Centralized content comparison utilities
  module ContentComparison
    # Compare two values using Crystal's Comparable interface
    def self.compare_values(a, b) : Int32?
      case {a, b}
      when {Time, Time}
        a.as(Time) <=> b.as(Time)
      when {String, String}
        a.as(String) <=> b.as(String)
      when {Int32, Int32}
        a.as(Int32) <=> b.as(Int32)
      when {Int64, Int64}
        a.as(Int64) <=> b.as(Int64)
      when {Float32, Float32}
        a.as(Float32) <=> b.as(Float32)
      when {Float64, Float64}
        a.as(Float64) <=> b.as(Float64)
      when {Number, Number}
        a.as(Number) <=> b.as(Number)
      when {Nil, Nil}
        0
      when {Nil, _}
        -1
      when {_, Nil}
        1
      else
        # Fallback to string comparison
        a.to_s <=> b.to_s
      end
    end

    # Compare content objects by a specific property
    def self.compare_by_property(content_a : Content, content_b : Content, property : String) : Int32?
      a_value = get_property_value(content_a, property)
      b_value = get_property_value(content_b, property)
      compare_values(a_value, b_value)
    end

    # Get property value from content, supporting nested properties
    def self.get_property_value(content : Content, property : String)
      case property
      when "title"
        content.title
      when "date"
        content.date
      when "url"
        content.url
      when "section"
        content.section
      when "tags"
        content.tags
      when "categories"
        content.categories
      when "author"
        content.author
      when "description"
        content.description
      when "draft"
        content.draft
      else
        # Try to get from frontmatter
        content.frontmatter[property]?.try(&.raw)
      end
    end

    # Sort content array by property
    def self.sort_by_property(content : Array(Content), property : String, reverse : Bool = false) : Array(Content)
      sorted = content.sort do |a, b|
        comparison = compare_by_property(a, b, property)
        comparison || 0
      end

      reverse ? sorted.reverse : sorted
    end
  end
end
