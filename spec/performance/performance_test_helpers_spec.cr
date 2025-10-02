require "benchmark"
require "../spec_helper"

# Shared performance test utilities to eliminate duplication across performance specs
module PerformanceTestHelpers
  # Shared test data constants
  TEST_STRINGS = ["title", "content", "date", "tags", "categories", "author", "description", "summary", "url", "permalink"]
  TEST_SYMBOLS = [:title, :content, :date, :tags, :categories, :author, :description, :summary, :url, :permalink]

  # Common test object for method dispatch benchmarks
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

  # Template processing simulation data
  TEMPLATE_VARS = {
    "title"   => "My Blog Post",
    "content" => "This is the content...",
    "date"    => "2024-01-01",
    "tags"    => "crystal, performance, benchmarks",
    "author"  => "Developer",
  }

  # Benchmark hash lookups with consistent reporting
  def self.benchmark_hash_lookups(string_hash : Hash(String, String), symbol_hash : Hash(Symbol, String))
    puts "\n=== Hash Lookup Performance (IPS) ==="
    Benchmark.ips do |x|
      x.report("String lookups") do
        TEST_STRINGS.each { |str| string_hash[str] }
      end
      x.report("Symbol lookups") do
        TEST_SYMBOLS.each { |sym| symbol_hash[sym] }
      end
    end
  end

  # Benchmark case statements with consistent reporting
  def self.benchmark_case_statements
    puts "\n=== Case Statement Performance (IPS) ==="
    Benchmark.ips do |x|
      x.report("String case statements") do
        TEST_STRINGS.each do |str|
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
        TEST_SYMBOLS.each do |sym|
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

  # Benchmark method dispatch with consistent reporting
  def self.benchmark_method_dispatch(test_obj : TestObject)
    puts "\n=== Method Dispatch Performance (IPS) ==="
    Benchmark.ips do |x|
      x.report("String method dispatch") do
        TEST_STRINGS.each do |str|
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
        TEST_SYMBOLS.each do |sym|
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

  # Benchmark template processing simulation
  def self.benchmark_template_processing
    puts "\n=== Template Processing Simulation (IPS) ==="
    Benchmark.ips do |x|
      x.report("String-based template processing") do
        TEMPLATE_VARS.each do |key, value|
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
        TEMPLATE_VARS.each do |key, value|
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

  # Memory usage benchmarking with consistent reporting
  def self.benchmark_memory_usage(&)
    Benchmark.memory do
      yield
    end
  end

  # Realtime benchmarking with consistent reporting
  def self.benchmark_realtime(iterations : Int32 = 100_000, &)
    Benchmark.realtime do
      iterations.times do
        yield
      end
    end
  end

  # Create test hashes for benchmarking
  def self.create_test_hashes : Tuple(Hash(String, String), Hash(Symbol, String))
    string_hash = {} of String => String
    symbol_hash = {} of Symbol => String

    TEST_STRINGS.each_with_index do |str, i|
      string_hash[str] = "value_#{i}"
      symbol_hash[TEST_SYMBOLS[i]] = "value_#{i}"
    end

    {string_hash, symbol_hash}
  end

  # Large collection memory benchmarking
  def self.benchmark_large_collections
    puts "\n=== Large Collection Memory Usage ==="

    large_string_memory = benchmark_memory_usage do
      large_string_array = Array(String).new(10000)
      10000.times { |i| large_string_array << "string_#{i}" }
      large_string_array
    end

    large_symbol_memory = benchmark_memory_usage do
      large_symbol_array = Array(Symbol).new(10000)
      # Use predefined symbols since we can't create them dynamically
      predefined_symbols = TEST_SYMBOLS
      10000.times { |i| large_symbol_array << predefined_symbols[i % predefined_symbols.size] }
      large_symbol_array
    end

    puts "Large string collection memory: #{large_string_memory} bytes"
    puts "Large symbol collection memory: #{large_symbol_memory} bytes"
    puts "Memory savings: #{(large_string_memory / large_symbol_memory.to_f).round(2)}x less memory"

    {large_string_memory, large_symbol_memory}
  end

  # Comprehensive performance analysis
  def self.comprehensive_performance_analysis(iterations : Int32 = 100_000)
    puts "\n=== Comprehensive Performance Analysis ==="

    # Hash lookups
    puts "\n--- Hash Lookups ---"
    string_hash, symbol_hash = create_test_hashes

    string_time = benchmark_realtime(iterations) do
      TEST_STRINGS.each(&.hash)
    end
    symbol_time = benchmark_realtime(iterations) do
      TEST_SYMBOLS.each(&.hash)
    end
    puts "String: #{string_time.total_seconds.round(4)}s"
    puts "Symbol: #{symbol_time.total_seconds.round(4)}s"
    puts "Improvement: #{(string_time.total_seconds / symbol_time.total_seconds).round(2)}x"

    # Equality checks
    puts "\n--- Equality Checks ---"
    string_time = benchmark_realtime(iterations) do
      TEST_STRINGS.each { |s| s == "title" }
    end
    symbol_time = benchmark_realtime(iterations) do
      TEST_SYMBOLS.each { |s| s == :title }
    end
    puts "String: #{string_time.total_seconds.round(4)}s"
    puts "Symbol: #{symbol_time.total_seconds.round(4)}s"
    puts "Improvement: #{(string_time.total_seconds / symbol_time.total_seconds).round(2)}x"

    # String conversion
    puts "\n--- String Conversion ---"
    string_time = benchmark_realtime(iterations) do
      TEST_STRINGS.each(&.to_s)
    end
    symbol_time = benchmark_realtime(iterations) do
      TEST_SYMBOLS.each(&.to_s)
    end
    puts "String: #{string_time.total_seconds.round(4)}s"
    puts "Symbol: #{symbol_time.total_seconds.round(4)}s"
    puts "Improvement: #{(string_time.total_seconds / symbol_time.total_seconds).round(2)}x"
  end

  # Check if performance tests should run
  def self.should_run_performance_tests? : Bool
    ENV.has_key?("LAPIS_INCLUDE_PERFORMANCE") || ENV.has_key?("CI")
  end
end
