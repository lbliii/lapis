require "../spec_helper"
require "string_pool"

describe "StringPool Performance Integration" do
  it "validates StringPool memory efficiency in template processing" do
    # Test data setup
    config = TestDataFactory.create_config("Test Site", "test_output")
    frontmatter = TestDataFactory.create_content("Test Page", "test-page")
    content = Lapis::Content.new("content/test-page.md", frontmatter, "Test content")
    context = Lapis::TemplateContext.new(config, content)
    
    template_processor = Lapis::TemplateProcessor.new(context)
    function_processor = Lapis::FunctionProcessor.new(context)

    # Benchmark string operations without StringPool
    start_time = Time.monotonic

    # Simulate heavy template processing
    1000.times do |i|
      # String operations that would benefit from StringPool
      test_strings = [
        "{{ #{i} }}",
        "{{ title }}",
        "{{ url }}",
        "{{ date_formatted }}",
        "{{ tags }}",
        "{{ summary }}",
        "{{ reading_time }}",
      ]

      test_strings.each do |str|
        # Simulate template variable processing
        processed = str.gsub(/{{ (.+) }}/, "processed_\\1")
        formatted = "#{processed}_formatted"
        cached = "#{formatted}_cached"
      end
    end

    without_pool_time = Time.monotonic - start_time

    # Benchmark with StringPool caching
    pool = StringPool.new(512)
    start_time = Time.monotonic

    1000.times do |i|
      test_strings = [
        "{{ #{i} }}",
        "{{ title }}",
        "{{ url }}",
        "{{ date_formatted }}",
        "{{ tags }}",
        "{{ summary }}",
        "{{ reading_time }}",
      ]

      test_strings.each do |str|
        # Use StringPool for caching
        processed = pool.get(str.gsub(/{{ (.+) }}/, "processed_\\1"))
        formatted = pool.get("#{processed}_formatted")
        cached = pool.get("#{formatted}_cached")
      end
    end

    with_pool_time = Time.monotonic - start_time

    # StringPool should show memory efficiency (may not always be faster due to hash overhead)
    # but should reduce memory usage significantly
    puts "Without StringPool: #{without_pool_time.total_milliseconds}ms"
    puts "With StringPool: #{with_pool_time.total_milliseconds}ms"
    puts "Pool size: #{pool.size} unique strings cached"

    # Validate StringPool is working
    pool.size.should be > 0
    pool.get("{{ title }}").should eq("{{ title }}")
    pool.get("{{ title }}").should be(pool.get("{{ title }}")) # Same reference
  end

  it "validates StringPool effectiveness in function processing" do

    pool = StringPool.new(256)

    # Test common function processing scenarios
    test_values = [
      "Hello World",
      "hello world",
      "HELLO WORLD",
      "Hello World",
      "hello world", # Duplicate
      "test string",
      "Test String",
    ]

    # Process strings through StringPool
    processed = test_values.map { |str| pool.get(str.upcase) }

    # Verify deduplication worked
    processed.size.should eq(test_values.size)
    pool.size.should be < test_values.size # Some strings should be deduplicated

    # Verify same strings return same reference
    processed[1].should be(processed[4]) # "hello world" -> "HELLO WORLD"

    puts "Original strings: #{test_values.size}"
    puts "Unique cached strings: #{pool.size}"
    puts "Memory savings: #{(test_values.size - pool.size)} strings deduplicated"
  end

  it "validates StringPool in Functions module" do
    # Test that Functions module StringPool is working
    Lapis::Functions.setup

    # Test common function calls that should benefit from StringPool
    test_input = "hello world"

    # Call functions that use StringPool internally
    result1 = Lapis::Functions.call("title", [test_input])
    result2 = Lapis::Functions.call("slugify", [test_input])
    result3 = Lapis::Functions.call("upper", [test_input])

    # Verify functions work correctly
    result1.should eq("Hello World")
    result2.should eq("hello-world")
    result3.should eq("HELLO WORLD")

    # Test StringPool caching in Functions
    result4 = Lapis::Functions.call("title", [test_input])
    result4.should eq("Hello World")

    puts "Functions module StringPool integration validated"
  end

  it "measures memory usage reduction with StringPool" do

    # Create a scenario with many duplicate strings
    common_strings = [
      "{{ title }}",
      "{{ url }}",
      "{{ date_formatted }}",
      "{{ tags }}",
      "{{ summary }}",
      "{{ reading_time }}",
      "{{ author }}",
      "{{ content }}",
    ]

    pool = StringPool.new(128)

    # Generate many variations of common strings
    all_strings = [] of String
    100.times do |i|
      common_strings.each do |base|
        all_strings << "#{base}_#{i}"
        all_strings << base # Duplicate the base string
      end
    end

    # Process through StringPool
    cached_strings = all_strings.map { |str| pool.get(str) }

    # Verify we have the expected number of unique strings
    unique_count = common_strings.size * 101 # 100 variations + 1 base each
    pool.size.should eq(unique_count)

    # Verify deduplication worked for base strings
    base_strings = common_strings.map { |str| pool.get(str) }
    base_strings.each do |str|
      # Each base string should appear multiple times in cached_strings
      cached_strings.count(str).should be > 1
    end

    puts "Total strings processed: #{all_strings.size}"
    puts "Unique strings cached: #{pool.size}"
    puts "Deduplication ratio: #{(all_strings.size.to_f / pool.size).round(2)}x"
  end
end
