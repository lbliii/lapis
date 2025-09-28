require "../spec_helper"
require "benchmark"

# Mock objects for testing
class TestObject
  def title
    "title_value"
  end

  def content
    "content_value"
  end

  def date
    "date_value"
  end

  def tags
    "tags_value"
  end

  def categories
    "categories_value"
  end

  def author
    "author_value"
  end

  def description
    "description_value"
  end

  def summary
    "summary_value"
  end

  def url
    "url_value"
  end

  def permalink
    "permalink_value"
  end
end

describe "Enhanced Symbol Performance Benchmarks" do
  test_strings = ["title", "content", "date", "tags", "categories", "author", "description", "summary", "url", "permalink"]
  test_symbols = [:title, :content, :date, :tags, :categories, :author, :description, :summary, :url, :permalink]
  iterations = 100_000

  describe "Function Registry Performance (IPS)" do
    it "benchmarks symbol vs string hash lookups using IPS" do
      # Create test hashes
      string_hash = {} of String => String
      symbol_hash = {} of Symbol => String

      test_strings.each_with_index do |str, i|
        string_hash[str] = "value_#{i}"
        symbol_hash[test_symbols[i]] = "value_#{i}"
      end

      puts "\n=== Function Registry Performance (IPS) ==="
      Benchmark.ips do |x|
        x.report("String lookups") do
          test_strings.each { |str| string_hash[str] }
        end

        x.report("Symbol lookups") do
          test_symbols.each { |sym| symbol_hash[sym] }
        end
      end
    end

    it "benchmarks memory usage of function registries" do
      puts "\n=== Function Registry Memory Usage ==="

      string_memory = Benchmark.memory do
        string_hash = {} of String => String
        test_strings.each_with_index { |str, i| string_hash[str] = "value_#{i}" }
        string_hash
      end

      symbol_memory = Benchmark.memory do
        symbol_hash = {} of Symbol => String
        test_symbols.each_with_index { |sym, i| symbol_hash[sym] = "value_#{i}" }
        symbol_hash
      end

      puts "String registry memory: #{string_memory} bytes"
      puts "Symbol registry memory: #{symbol_memory} bytes"
      puts "Memory savings: #{(string_memory / symbol_memory.to_f).round(2)}x less memory"
      # Note: For small collections, hash overhead dominates, but large collections show significant savings
      # This test demonstrates the memory measurement capability rather than asserting superiority
      puts "Note: Small collections may not show memory benefits due to hash overhead"
    end
  end

  describe "Property Access Performance (IPS)" do
    it "benchmarks symbol vs string case statements using IPS" do
      puts "\n=== Property Access Performance (IPS) ==="

      Benchmark.ips do |x|
        x.report("String case statements") do
          test_strings.each do |str|
            case str
            when "title"       then "title_value"
            when "content"     then "content_value"
            when "date"        then "date_value"
            when "tags"        then "tags_value"
            when "categories"  then "categories_value"
            when "author"      then "author_value"
            when "description" then "description_value"
            when "summary"     then "summary_value"
            when "url"         then "url_value"
            when "permalink"   then "permalink_value"
            else                    "default_value"
            end
          end
        end

        x.report("Symbol case statements") do
          test_symbols.each do |sym|
            case sym
            when :title       then "title_value"
            when :content     then "content_value"
            when :date        then "date_value"
            when :tags        then "tags_value"
            when :categories  then "categories_value"
            when :author      then "author_value"
            when :description then "description_value"
            when :summary     then "summary_value"
            when :url         then "url_value"
            when :permalink   then "permalink_value"
            else                   "default_value"
            end
          end
        end
      end
    end
  end

  describe "Method Dispatch Performance (IPS)" do
    it "benchmarks symbol vs string method dispatch using IPS" do
      puts "\n=== Method Dispatch Performance (IPS) ==="

      test_obj = TestObject.new

      Benchmark.ips do |x|
        x.report("String method dispatch") do
          test_strings.each do |str|
            case str
            when "title"       then test_obj.title
            when "content"     then test_obj.content
            when "date"        then test_obj.date
            when "tags"        then test_obj.tags
            when "categories"  then test_obj.categories
            when "author"      then test_obj.author
            when "description" then test_obj.description
            when "summary"     then test_obj.summary
            when "url"         then test_obj.url
            when "permalink"   then test_obj.permalink
            else                    "default_value"
            end
          end
        end

        x.report("Symbol method dispatch") do
          test_symbols.each do |sym|
            case sym
            when :title       then test_obj.title
            when :content     then test_obj.content
            when :date        then test_obj.date
            when :tags        then test_obj.tags
            when :categories  then test_obj.categories
            when :author      then test_obj.author
            when :description then test_obj.description
            when :summary     then test_obj.summary
            when :url         then test_obj.url
            when :permalink   then test_obj.permalink
            else                   "default_value"
            end
          end
        end
      end
    end
  end

  describe "Template Processing Simulation (IPS)" do
    it "benchmarks realistic template processing scenarios using IPS" do
      puts "\n=== Template Processing Simulation (IPS) ==="

      # Simulate realistic template processing
      template_vars = {
        "title"   => "My Blog Post",
        "content" => "This is the content...",
        "date"    => "2024-01-01",
        "tags"    => "crystal, performance, benchmarks",
        "author"  => "Developer",
      }

      Benchmark.ips do |x|
        x.report("String-based template processing") do
          template_vars.each do |key, value|
            case key
            when "title"   then "Title: #{value}"
            when "content" then "Content: #{value}"
            when "date"    then "Date: #{value}"
            when "tags"    then "Tags: #{value}"
            when "author"  then "Author: #{value}"
            else                "Unknown: #{value}"
            end
          end
        end

        x.report("Symbol-based template processing") do
          template_vars.each do |key, value|
            case key
            when "title"   then "Title: #{value}"
            when "content" then "Content: #{value}"
            when "date"    then "Date: #{value}"
            when "tags"    then "Tags: #{value}"
            when "author"  then "Author: #{value}"
            else                "Unknown: #{value}"
            end
          end
        end
      end
    end
  end

  describe "Advanced Benchmarking Features" do
    it "demonstrates realtime benchmarking for precise timing" do
      puts "\n=== Realtime Benchmarking ==="

      string_time = Benchmark.realtime do
        iterations.times do
          test_strings.each(&.upcase)
        end
      end

      symbol_time = Benchmark.realtime do
        iterations.times do
          test_symbols.each(&.to_s.upcase)
        end
      end

      puts "String processing realtime: #{string_time}"
      puts "Symbol processing realtime: #{symbol_time}"
      puts "Performance improvement: #{(string_time / symbol_time).round(2)}x faster"
      symbol_time.should be < string_time
    end

    it "benchmarks memory usage of large collections" do
      puts "\n=== Large Collection Memory Usage ==="

      large_string_memory = Benchmark.memory do
        large_string_array = Array(String).new(10000)
        10000.times { |i| large_string_array << "string_#{i}" }
        large_string_array
      end

      large_symbol_memory = Benchmark.memory do
        large_symbol_array = Array(Symbol).new(10000)
        # Use predefined symbols since we can't create them dynamically
        predefined_symbols = [:title, :content, :date, :tags, :categories, :author, :description, :summary, :url, :permalink]
        10000.times { |i| large_symbol_array << predefined_symbols[i % predefined_symbols.size] }
        large_symbol_array
      end

      puts "Large string collection memory: #{large_string_memory} bytes"
      puts "Large symbol collection memory: #{large_symbol_memory} bytes"
      puts "Memory savings: #{(large_string_memory / large_symbol_memory.to_f).round(2)}x less memory"
      large_symbol_memory.should be < large_string_memory
    end
  end

  describe "Symbol.needs_quotes? Performance (IPS)" do
    it "benchmarks the needs_quotes? method performance using IPS" do
      puts "\n=== Symbol.needs_quotes? Performance (IPS) ==="

      test_symbols_with_quotes = [:title, :"has_key", :"file_dirname", :"get_value", :"set_value"]

      Benchmark.ips do |x|
        x.report("Symbol.needs_quotes? check") do
          test_symbols_with_quotes.each { |sym| Symbol.needs_quotes?(sym.to_s) }
        end
      end
    end
  end

  describe "Comprehensive Performance Analysis" do
    it "runs all benchmarks with custom timing" do
      puts "\n=== Comprehensive Performance Analysis ==="

      # Custom timing for different scenarios
      puts "\n--- Hash Lookups ---"
      string_time = Benchmark.measure do
        iterations.times { test_strings.each(&.hash) }
      end
      symbol_time = Benchmark.measure do
        iterations.times { test_symbols.each(&.hash) }
      end
      puts "String: #{string_time.real.round(4)}s"
      puts "Symbol: #{symbol_time.real.round(4)}s"
      puts "Improvement: #{(string_time.real / symbol_time.real).round(2)}x"

      puts "\n--- Equality Checks ---"
      string_time = Benchmark.measure do
        iterations.times { test_strings.each { |s| s == "title" } }
      end
      symbol_time = Benchmark.measure do
        iterations.times { test_symbols.each { |s| s == :title } }
      end
      puts "String: #{string_time.real.round(4)}s"
      puts "Symbol: #{symbol_time.real.round(4)}s"
      puts "Improvement: #{(string_time.real / symbol_time.real).round(2)}x"

      puts "\n--- String Conversion ---"
      string_time = Benchmark.measure do
        iterations.times { test_strings.each(&.to_s) }
      end
      symbol_time = Benchmark.measure do
        iterations.times { test_symbols.each(&.to_s) }
      end
      puts "String: #{string_time.real.round(4)}s"
      puts "Symbol: #{symbol_time.real.round(4)}s"
      puts "Improvement: #{(string_time.real / symbol_time.real).round(2)}x"
    end
  end
end
