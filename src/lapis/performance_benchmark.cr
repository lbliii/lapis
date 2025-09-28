require "benchmark"
require "log"
require "./logger"
require "./exceptions"

module Lapis
  # Performance benchmarking and measurement for Lapis
  class PerformanceBenchmark
    property results : Hash(String, Benchmark::BM::Tms) = {} of String => Benchmark::BM::Tms

    def initialize
    end

    # Benchmark a single operation
    def benchmark(name : String, &)
      Logger.debug("Starting benchmark", operation: name)

      job = Benchmark.measure do
        yield
      end

      @results[name] = job

      Logger.info("Benchmark completed",
        operation: name,
        real_time: format_time(job.real),
        user_time: format_time(job.utime),
        system_time: format_time(job.stime),
        total_time: format_time(job.total))

      job
    end

    # Compare multiple operations
    def compare(name : String, operations : Hash(String, ->), iterations : Int32 = 1)
      Logger.info("Starting comparison benchmark", name: name, iterations: iterations.to_s)

      comparison = Benchmark.bm do |x|
        operations.each do |op_name, op_proc|
          x.report(op_name) do
            iterations.times do
              op_proc.call
            end
          end
        end
      end

      Logger.info("Comparison benchmark completed", name: name)
      comparison
    end

    # Memory-aware benchmarking
    def benchmark_with_memory(name : String, &)
      Logger.debug("Starting memory-aware benchmark", operation: name)

      # Get initial memory stats
      initial_memory = Lapis.memory_manager.current_memory_usage

      # Run benchmark
      job = benchmark(name) do
        yield
      end

      # Get final memory stats
      final_memory = Lapis.memory_manager.current_memory_usage
      memory_delta = final_memory - initial_memory

      Logger.info("Memory-aware benchmark completed",
        operation: name,
        real_time: format_time(job.real),
        memory_delta: Lapis.memory_manager.format_bytes(memory_delta))

      job
    end

    # Benchmark file operations
    def benchmark_file_operation(operation : String, file_path : String, &)
      Logger.debug("Starting file operation benchmark", operation: operation, file: file_path)

      job = benchmark("#{operation}_#{File.basename(file_path)}") do
        yield
      end

      file_size = File.exists?(file_path) ? File.info(file_path).size : 0

      Logger.info("File operation benchmark completed",
        operation: operation,
        file: file_path,
        file_size: Lapis.memory_manager.format_bytes(file_size),
        real_time: format_time(job.real))

      job
    end

    # Benchmark template rendering
    def benchmark_template_rendering(template_name : String, content_count : Int32, &)
      Logger.debug("Starting template rendering benchmark",
        template: template_name,
        content_count: content_count.to_s)

      job = benchmark("template_#{template_name}_#{content_count}") do
        yield
      end

      Logger.info("Template rendering benchmark completed",
        template: template_name,
        content_count: content_count.to_s,
        real_time: format_time(job.real),
        per_content: format_time(job.real / content_count))

      job
    end

    # Benchmark build operations
    def benchmark_build_phase(phase : String, &)
      Logger.info("Starting build phase benchmark", phase: phase)

      job = benchmark_with_memory("build_#{phase}") do
        yield
      end

      Logger.info("Build phase benchmark completed",
        phase: phase,
        real_time: format_time(job.real),
        user_time: format_time(job.utime),
        system_time: format_time(job.stime))

      job
    end

    # Get benchmark results
    def get_results : Hash(String, Benchmark::BM::Tms)
      @results
    end

    # Get fastest operation
    def fastest_operation : String?
      return nil if @results.empty?

      fastest = @results.min_by { |_, tms| tms.real }
      fastest[0] if fastest
    end

    # Get slowest operation
    def slowest_operation : String?
      return nil if @results.empty?

      slowest = @results.max_by { |_, tms| tms.real }
      slowest[0] if slowest
    end

    # Generate performance report
    def generate_report : String
      return "No benchmarks performed" if @results.empty?

      report = String.build do |str|
        str << "Performance Benchmark Report\n"
        str << "=" * 50 << "\n\n"

        @results.each do |name, tms|
          str << "#{name}:\n"
          str << "  Real time: #{format_time(tms.real)}\n"
          str << "  User time: #{format_time(tms.utime)}\n"
          str << "  System time: #{format_time(tms.stime)}\n"
          str << "  Total time: #{format_time(tms.total)}\n\n"
        end

        if fastest = fastest_operation
          str << "Fastest operation: #{fastest} (#{format_time(@results[fastest].real)})\n"
        end

        if slowest = slowest_operation
          str << "Slowest operation: #{slowest} (#{format_time(@results[slowest].real)})\n"
        end
      end

      report
    end

    # Clear all benchmarks
    def clear
      @results.clear
      Logger.debug("Benchmarks cleared")
    end

    private def format_time(time : Float64) : String
      if time < 0.001
        "#{(time * 1_000_000).round(2)}μs"
      elsif time < 1.0
        "#{(time * 1000).round(2)}ms"
      else
        "#{time.round(3)}s"
      end
    end
  end

  # Global benchmark instance
  @@benchmark : PerformanceBenchmark?

  def self.benchmark : PerformanceBenchmark
    @@benchmark ||= PerformanceBenchmark.new
  end

  def self.benchmark=(bench : PerformanceBenchmark)
    @@benchmark = bench
  end
end
