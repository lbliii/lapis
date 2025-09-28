require "../spec_helper"

describe Lapis::PerformanceBenchmark do
  describe "#benchmark" do
    it "measures operation time", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      result = benchmark.benchmark("test_operation") do
        sleep(1.millisecond) # Small delay to measure
        "test_result"
      end

      result.should be_a(Benchmark::BM::Tms)
      benchmark.results.keys.should contain("test_operation")
    end

    it "stores benchmark results", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      benchmark.benchmark("test") do
        "result"
      end

      benchmark.results.size.should eq(1)
      benchmark.results["test"].should be_a(Benchmark::BM::Tms)
    end
  end

  describe "#compare" do
    it "compares multiple operations", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      operations = {
        "fast" => -> { },
        "slow" => -> { sleep(1.millisecond) },
      }

      result = benchmark.compare("test_comparison", operations)
      result.should be_a(Benchmark::BM::Job)
    end
  end

  describe "#benchmark_with_memory" do
    it "measures memory usage during operation", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      result = benchmark.benchmark_with_memory("memory_test") do
        "test_result"
      end

      result.should be_a(Benchmark::BM::Tms)
    end
  end

  describe "#fastest_operation" do
    it "returns fastest operation", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      benchmark.benchmark("fast") do
        "fast"
      end

      benchmark.benchmark("slow") do
        sleep(1.millisecond)
        "slow"
      end

      fastest = benchmark.fastest_operation
      fastest.should eq("fast")
    end

    it "returns nil when no operations", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new
      benchmark.fastest_operation.should be_nil
    end
  end

  describe "#slowest_operation" do
    it "returns slowest operation", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      benchmark.benchmark("fast") do
        "fast"
      end

      benchmark.benchmark("slow") do
        sleep(1.millisecond)
        "slow"
      end

      slowest = benchmark.slowest_operation
      slowest.should eq("slow")
    end
  end

  describe "#clear" do
    it "clears all benchmark results", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      benchmark.benchmark("test") do
        "result"
      end

      benchmark.results.size.should eq(1)
      benchmark.clear
      benchmark.results.size.should eq(0)
    end
  end

  describe "#generate_report" do
    it "generates performance report", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new

      benchmark.benchmark("test") do
        "result"
      end

      report = benchmark.generate_report
      report.should be_a(String)
      report.should contain("Performance Benchmark Report")
      report.should contain("test:")
    end

    it "returns message when no benchmarks", tags: [TestTags::FAST, TestTags::UNIT] do
      benchmark = Lapis::PerformanceBenchmark.new
      report = benchmark.generate_report
      report.should eq("No benchmarks performed")
    end
  end
end
