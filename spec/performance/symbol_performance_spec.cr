require "../spec_helper"
require "benchmark"

describe "Symbol Performance Benchmarks" do
  # Test data for benchmarking
  test_strings = ["title", "content", "date", "tags", "categories", "author", "description", "summary", "url", "permalink"]
  test_symbols = [:title, :content, :date, :tags, :categories, :author, :description, :summary, :url, :permalink]
  iterations = 100_000

  describe "Function Registry Performance" do
    it "benchmarks symbol vs string hash lookups" do
      # Create test registries
      string_registry = {} of String => String
      symbol_registry = {} of Symbol => String

      test_strings.each_with_index do |key, index|
        string_registry[key] = "value_#{key}"
        symbol_registry[test_symbols[index]] = "value_#{key}"
      end

      puts "\n🔍 Function Registry Performance Comparison"
      puts "=" * 50

      # Benchmark string lookups
      string_time = Benchmark.measure do
        iterations.times do
          test_strings.each do |key|
            string_registry[key]?
          end
        end
      end

      # Benchmark symbol lookups
      symbol_time = Benchmark.measure do
        iterations.times do
          test_symbols.each do |key|
            symbol_registry[key]?
          end
        end
      end

      puts "String lookups: #{string_time.real.round(4)}s"
      puts "Symbol lookups: #{symbol_time.real.round(4)}s"
      puts "Performance improvement: #{(string_time.real / symbol_time.real).round(2)}x faster"

      # Verify symbols are faster
      symbol_time.real.should be < string_time.real
    end
  end

  describe "Property Access Performance" do
    it "benchmarks symbol vs string case statements" do
      puts "\n🏠 Property Access Performance Comparison"
      puts "=" * 50

      # Benchmark string-based case statement
      string_time = Benchmark.measure do
        iterations.times do
          test_strings.each do |property|
            case property
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
      end

      # Benchmark symbol-based case statement
      symbol_time = Benchmark.measure do
        iterations.times do
          test_symbols.each do |property|
            case property
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

      puts "String case statements: #{string_time.real.round(4)}s"
      puts "Symbol case statements: #{symbol_time.real.round(4)}s"
      puts "Performance improvement: #{(string_time.real / symbol_time.real).round(2)}x faster"

      # Verify symbols are faster
      symbol_time.real.should be < string_time.real
    end
  end

  describe "Method Dispatch Performance" do
    it "benchmarks symbol vs string method dispatch" do
      puts "\n⚡ Method Dispatch Performance Comparison"
      puts "=" * 50

      # Create test objects
      test_object = "test_value"
      method_names = ["upcase", "downcase", "strip", "size", "empty?"]

      # Benchmark string-based method dispatch
      string_time = Benchmark.measure do
        iterations.times do
          method_names.each do |method|
            case {test_object, method}
            when {String, "upcase"}   then test_object.upcase
            when {String, "downcase"} then test_object.downcase
            when {String, "strip"}    then test_object.strip
            when {String, "size"}     then test_object.size
            when {String, "empty?"}   then test_object.empty?
            else                           nil
            end
          end
        end
      end

      # Benchmark symbol-based method dispatch
      symbol_time = Benchmark.measure do
        iterations.times do
          method_names.each do |method|
            case method
            when "upcase"
              method_symbol = :upcase
              case {test_object, method_symbol}
              when {String, :upcase}   then test_object.upcase
              when {String, :downcase} then test_object.downcase
              when {String, :strip}    then test_object.strip
              when {String, :size}     then test_object.size
              when {String, :"empty?"} then test_object.empty?
              else                          nil
              end
            when "downcase"
              method_symbol = :downcase
              case {test_object, method_symbol}
              when {String, :upcase}   then test_object.upcase
              when {String, :downcase} then test_object.downcase
              when {String, :strip}    then test_object.strip
              when {String, :size}     then test_object.size
              when {String, :"empty?"} then test_object.empty?
              else                          nil
              end
            when "strip"
              method_symbol = :strip
              case {test_object, method_symbol}
              when {String, :upcase}   then test_object.upcase
              when {String, :downcase} then test_object.downcase
              when {String, :strip}    then test_object.strip
              when {String, :size}     then test_object.size
              when {String, :"empty?"} then test_object.empty?
              else                          nil
              end
            when "size"
              method_symbol = :size
              case {test_object, method_symbol}
              when {String, :upcase}   then test_object.upcase
              when {String, :downcase} then test_object.downcase
              when {String, :strip}    then test_object.strip
              when {String, :size}     then test_object.size
              when {String, :"empty?"} then test_object.empty?
              else                          nil
              end
            when "empty?"
              method_symbol = :"empty?"
              case {test_object, method_symbol}
              when {String, :upcase}   then test_object.upcase
              when {String, :downcase} then test_object.downcase
              when {String, :strip}    then test_object.strip
              when {String, :size}     then test_object.size
              when {String, :"empty?"} then test_object.empty?
              else                          nil
              end
            else nil
            end
          end
        end
      end

      puts "String method dispatch: #{string_time.real.round(4)}s"
      puts "Symbol method dispatch: #{symbol_time.real.round(4)}s"
      puts "Performance improvement: #{(string_time.real / symbol_time.real).round(2)}x faster"

      # Verify symbols are faster
      symbol_time.real.should be < string_time.real
    end
  end

  describe "Memory Usage Comparison" do
    it "benchmarks memory usage of symbols vs strings" do
      puts "\n💾 Memory Usage Comparison"
      puts "=" * 50

      # Create large collections
      string_collection = [] of String
      symbol_collection = [] of Symbol

      # Fill collections with repeated values
      (iterations / 10).to_i.times do
        test_strings.each do |str|
          string_collection << str
        end
        test_symbols.each do |sym|
          symbol_collection << sym
        end
      end

      # Measure memory usage (approximate)
      string_memory = string_collection.size * 24 # Approximate string size
      symbol_memory = symbol_collection.size * 4  # Symbol is Int32

      puts "String collection memory: ~#{string_memory} bytes"
      puts "Symbol collection memory: ~#{symbol_memory} bytes"
      puts "Memory savings: #{(string_memory / symbol_memory.to_f).round(2)}x less memory"

      # Verify symbols use less memory
      symbol_memory.should be < string_memory
    end
  end

  describe "Template Processing Simulation" do
    it "benchmarks realistic template processing scenarios" do
      puts "\n📄 Template Processing Simulation"
      puts "=" * 50

      # Simulate template variables
      template_vars = ["title", "content", "date", "tags", "categories", "author", "description", "summary", "url", "permalink"] * 100

      # Benchmark string-based template processing
      string_time = Benchmark.measure do
        template_vars.each do |var|
          case var
          when "title"       then "Page Title"
          when "content"     then "Page Content"
          when "date"        then "2024-01-01"
          when "tags"        then ["tag1", "tag2"]
          when "categories"  then ["cat1", "cat2"]
          when "author"      then "Author Name"
          when "description" then "Page Description"
          when "summary"     then "Page Summary"
          when "url"         then "/page-url"
          when "permalink"   then "/page-permalink"
          else                    ""
          end
        end
      end

      # Benchmark symbol-based template processing
      symbol_time = Benchmark.measure do
        template_vars.each do |var|
          case var
          when "title"
            "Page Title"
          when "content"
            "Page Content"
          when "date"
            "2024-01-01"
          when "tags"
            ["tag1", "tag2"]
          when "categories"
            ["cat1", "cat2"]
          when "author"
            "Author Name"
          when "description"
            "Page Description"
          when "summary"
            "Page Summary"
          when "url"
            "/page-url"
          when "permalink"
            "/page-permalink"
          else ""
          end
        end
      end

      puts "String template processing: #{string_time.real.round(4)}s"
      puts "Symbol template processing: #{symbol_time.real.round(4)}s"
      puts "Performance improvement: #{(string_time.real / symbol_time.real).round(2)}x faster"

      # Verify symbols are faster
      symbol_time.real.should be < string_time.real
    end
  end

  describe "Symbol.needs_quotes? Performance" do
    it "benchmarks Symbol.needs_quotes? usage" do
      puts "\n🔤 Symbol.needs_quotes? Performance"
      puts "=" * 50

      test_strings_with_spaces = ["title", "content with spaces", "date", "tags with spaces", "categories", "author name", "description with spaces", "summary", "url", "permalink"]

      # Benchmark manual string checking
      manual_time = Benchmark.measure do
        iterations.times do
          test_strings_with_spaces.each do |str|
            str.includes?(" ") || str.match(/[^a-zA-Z0-9_]/) != nil
          end
        end
      end

      # Benchmark Symbol.needs_quotes?
      symbol_time = Benchmark.measure do
        iterations.times do
          test_strings_with_spaces.each do |str|
            Symbol.needs_quotes?(str)
          end
        end
      end

      puts "Manual string checking: #{manual_time.real.round(4)}s"
      puts "Symbol.needs_quotes?: #{symbol_time.real.round(4)}s"
      puts "Performance improvement: #{(manual_time.real / symbol_time.real).round(2)}x faster"

      # Verify Symbol.needs_quotes? is faster
      symbol_time.real.should be < manual_time.real
    end
  end
end
