require "../spec_helper"
require "../../src/lapis/safe_cast"
require "../../src/lapis/functions"
require "benchmark"

describe "String Performance Optimizations" do
  describe "Slugify Performance" do
    it "compares old vs new slugify performance" do
      test_strings = [
        "Hello World! This is a test string with special characters: @#$%",
        "Hello 世界! This is a test with Unicode characters: café, naïve, résumé",
        "A very long string with many special characters !@#$%^&*()_+-=[]{}|;':\",./<>? and Unicode: 世界, café, naïve, résumé, こんにちは, مرحبا, שלום",
        "Simple string",
        "String with numbers 123 and symbols !@#",
      ]

      test_strings.each do |test_string|
        Benchmark.ips do |x|
          x.report("old_slugify") do
            # Old implementation
            test_string.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
          end

          x.report("new_slugify") do
            # New optimized implementation
            Lapis::SafeCast.optimized_slugify(test_string)
          end
        end
      end
    end
  end

  describe "String Building Performance" do
    it "compares string concatenation methods" do
      parts = ["Hello", " ", "World", "!", " ", "This", " ", "is", " ", "a", " ", "test"]

      Benchmark.ips do |x|
        x.report("string_interpolation") do
          "#{parts[0]}#{parts[1]}#{parts[2]}#{parts[3]}#{parts[4]}#{parts[5]}#{parts[6]}#{parts[7]}#{parts[8]}#{parts[9]}#{parts[10]}#{parts[11]}"
        end

        x.report("string_build") do
          String.build do |io|
            parts.each { |part| io << part }
          end
        end

        x.report("join") do
          parts.join
        end
      end
    end
  end

  describe "Unicode Processing Performance" do
    it "benchmarks Unicode normalization" do
      test_strings = [
        "café",
        "naïve",
        "résumé",
        "Hello 世界",
        "こんにちは",
        "مرحبا",
        "שלום",
      ]

      test_strings.each do |test_string|
        Benchmark.ips do |x|
          x.report("unicode_normalize_nfc") do
            test_string.unicode_normalize(:nfc)
          end

          x.report("unicode_normalize_nfd") do
            test_string.unicode_normalize(:nfd)
          end

          x.report("unicode_normalize_nfkc") do
            test_string.unicode_normalize(:nfkc)
          end

          x.report("unicode_normalize_nfkd") do
            test_string.unicode_normalize(:nfkd)
          end
        end
      end
    end
  end

  describe "Character Analysis Performance" do
    it "benchmarks character counting methods" do
      test_string = "Hello 世界! This is a test string with numbers 123 and symbols @#$%"

      Benchmark.ips do |x|
        x.report("chars_count") do
          test_string.chars.count(&.letter?)
        end

        x.report("each_char_count") do
          count = 0
          test_string.each_char do |char|
            count += 1 if char.letter?
          end
          count
        end

        x.report("codepoints_count") do
          test_string.codepoints.count(&.chr.letter?)
        end
      end
    end
  end

  describe "String Manipulation Performance" do
    it "benchmarks string transformation methods" do
      test_string = "Hello World! This is a test string with special characters: @#$%"

      Benchmark.ips do |x|
        x.report("upcase") do
          test_string.upcase
        end

        x.report("downcase") do
          test_string.downcase
        end

        x.report("strip") do
          test_string.strip
        end

        x.report("reverse") do
          test_string.reverse
        end

        x.report("tr") do
          test_string.tr("lo", "XO")
        end

        x.report("squeeze") do
          test_string.squeeze
        end

        x.report("delete") do
          test_string.delete("lo")
        end
      end
    end
  end

  describe "Memory Usage" do
    it "measures memory usage for large string operations" do
      large_string = "Hello World! " * 1000

      # Measure memory before
      GC.collect
      memory_before = GC.stats.heap_size

      # Perform operations
      result = String.build do |io|
        io << large_string.upcase
        io << " "
        io << large_string.downcase
        io << " "
        io << large_string.strip
      end

      # Measure memory after
      GC.collect
      memory_after = GC.stats.heap_size

      # Verify result is correct
      result.size.should be > large_string.size

      # Memory usage should be reasonable
      memory_increase = memory_after - memory_before
      memory_increase.should be < 10_000_000 # Less than 10MB increase
    end
  end
end
