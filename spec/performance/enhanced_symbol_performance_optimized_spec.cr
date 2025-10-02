require "../spec_helper"
require "./performance_test_helpers"

# Optimized performance tests using shared helpers to eliminate duplication
describe "Enhanced Symbol Performance Benchmarks (Optimized)" do
  if PerformanceTestHelpers.should_run_performance_tests?
    iterations = 100_000

    describe "Function Registry Performance (IPS)" do
      it "benchmarks symbol vs string hash lookups using IPS" do
        string_hash, symbol_hash = PerformanceTestHelpers.create_test_hashes
        PerformanceTestHelpers.benchmark_hash_lookups(string_hash, symbol_hash)
      end

      it "benchmarks memory usage of function registries" do
        puts "\n=== Function Registry Memory Usage ==="

        string_memory = PerformanceTestHelpers.benchmark_memory_usage do
          string_hash, _ = PerformanceTestHelpers.create_test_hashes
          string_hash
        end

        symbol_memory = PerformanceTestHelpers.benchmark_memory_usage do
          _, symbol_hash = PerformanceTestHelpers.create_test_hashes
          symbol_hash
        end

        puts "String registry memory: #{string_memory} bytes"
        puts "Symbol registry memory: #{symbol_memory} bytes"
        puts "Memory savings: #{(string_memory / symbol_memory.to_f).round(2)}x less memory"
        puts "Note: Small collections may not show memory benefits due to hash overhead"
      end
    end

    describe "Property Access Performance (IPS)" do
      it "benchmarks symbol vs string case statements using IPS" do
        PerformanceTestHelpers.benchmark_case_statements
      end
    end

    describe "Method Dispatch Performance (IPS)" do
      it "benchmarks symbol vs string method dispatch using IPS" do
        test_obj = PerformanceTestHelpers::TestObject.new
        PerformanceTestHelpers.benchmark_method_dispatch(test_obj)
      end
    end

    describe "Template Processing Simulation (IPS)" do
      it "benchmarks realistic template processing scenarios using IPS" do
        puts "\n=== Template Processing Simulation (IPS) ==="
        PerformanceTestHelpers.benchmark_template_processing
      end
    end

    describe "Advanced Benchmarking Features" do
      it "demonstrates realtime benchmarking for precise timing" do
        puts "\n=== Realtime Benchmarking ==="

        string_time = PerformanceTestHelpers.benchmark_realtime(iterations) do
          PerformanceTestHelpers::TEST_STRINGS.each(&.upcase)
        end

        symbol_time = PerformanceTestHelpers.benchmark_realtime(iterations) do
          PerformanceTestHelpers::TEST_SYMBOLS.each(&.to_s.upcase)
        end

        puts "String processing realtime: #{string_time}"
        puts "Symbol processing realtime: #{symbol_time}"
        puts "Performance improvement: #{(string_time / symbol_time).round(2)}x faster"
        symbol_time.should be < string_time
      end

      it "benchmarks memory usage of large collections" do
        puts "\n=== Large Collection Memory Usage ==="
        string_memory, symbol_memory = PerformanceTestHelpers.benchmark_large_collections
        symbol_memory.should be < string_memory
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
        PerformanceTestHelpers.comprehensive_performance_analysis(iterations)
      end
    end
  else
    pending "Performance tests skipped (use LAPIS_INCLUDE_PERFORMANCE=1 to run)"
  end
end
