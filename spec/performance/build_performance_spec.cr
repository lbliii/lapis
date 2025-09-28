require "../spec_helper"

describe "Build Performance" do
  describe "benchmarking" do
    it "benchmarks build operations", tags: [TestTags::PERFORMANCE] do
      config = TestDataFactory.create_config("Benchmark Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        # Create multiple content files for benchmarking
        5.times do |i|
          content_text = <<-MD
          ---
          title: Benchmark Test #{i + 1}
          date: 2024-01-#{15 + i}
          layout: post
          ---

          # Benchmark Test #{i + 1}

          This is content #{i + 1} for benchmarking.

          ## Performance Testing

          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

          ## Additional Content

          Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
          MD

          File.write(File.join(content_dir, "benchmark-test-#{i + 1}.md"), content_text)
        end

        # Benchmark build operations
        benchmark = Lapis::PerformanceBenchmark.new

        # Benchmark content loading
        content_result = benchmark.benchmark("load_content") do
          Lapis::Content.load_all(content_dir)
        end

        content_result.should be_a(Benchmark::BM::Tms)

        # Benchmark template rendering
        template_result = benchmark.benchmark("render_templates") do
          template_engine = Lapis::TemplateEngine.new(config)
          content = Lapis::Content.load_all(content_dir)
          content.each do |c|
            template_engine.render_all_formats(c)
          end
        end

        template_result.should be_a(Benchmark::BM::Tms)

        # Benchmark full build
        build_result = benchmark.benchmark("full_build") do
          generator = Lapis::Generator.new(config)
          generator.build
        end

        build_result.should be_a(Benchmark::BM::Tms)

        # Generate performance report
        report = benchmark.generate_report
        report.should contain("load_content")
        report.should contain("render_templates")
        report.should contain("full_build")

        Lapis::Logger.info("Performance benchmark completed",
          fastest: benchmark.fastest_operation,
          slowest: benchmark.slowest_operation)
      end
    end

    it "compares different build strategies", tags: [TestTags::PERFORMANCE] do
      config = TestDataFactory.create_config("Compare Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Compare Test
        date: 2024-01-15
        layout: post
        ---

        # Compare Test

        This tests build strategy comparison.
        MD

        File.write(File.join(content_dir, "compare-test.md"), content_text)

        # Compare different build strategies
        benchmark = Lapis::PerformanceBenchmark.new

        operations = {
          "sequential" => -> {
            config.build_config.parallel = false
            generator = Lapis::Generator.new(config)
            generator.build
          },
          "parallel" => -> {
            config.build_config.parallel = true
            generator = Lapis::Generator.new(config)
            generator.build
          },
        }

        comparison_result = benchmark.compare("build_strategies", operations)
        comparison_result.should be_a(Benchmark::BM::Job)

        Lapis::Logger.info("Build strategy comparison completed")
      end
    end

    it "benchmarks memory-aware operations", tags: [TestTags::PERFORMANCE] do
      config = TestDataFactory.create_config("Memory Benchmark Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Memory Benchmark Test
        date: 2024-01-15
        layout: post
        ---

        # Memory Benchmark Test

        This tests memory-aware benchmarking.
        MD

        File.write(File.join(content_dir, "memory-benchmark-test.md"), content_text)

        # Benchmark with memory monitoring
        benchmark = Lapis::PerformanceBenchmark.new

        result = benchmark.benchmark_with_memory("memory_aware_build") do
          generator = Lapis::Generator.new(config)
          generator.build
        end

        result.should be_a(Benchmark::BM::Tms)

        Lapis::Logger.info("Memory-aware benchmark completed")
      end
    end
  end

  describe "performance monitoring" do
    it "monitors build performance over time", tags: [TestTags::PERFORMANCE] do
      config = TestDataFactory.create_config("Monitor Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Monitor Test
        date: 2024-01-15
        layout: post
        ---

        # Monitor Test

        This tests performance monitoring.
        MD

        File.write(File.join(content_dir, "monitor-test.md"), content_text)

        # Monitor multiple builds
        benchmark = Lapis::PerformanceBenchmark.new

        3.times do |i|
          result = benchmark.benchmark("build_#{i + 1}") do
            generator = Lapis::Generator.new(config)
            generator.build
          end

          result.should be_a(Benchmark::BM::Tms)
        end

        # Check performance trends
        report = benchmark.generate_report
        report.should contain("build_1")
        report.should contain("build_2")
        report.should contain("build_3")

        Lapis::Logger.info("Performance monitoring completed",
          total_operations: benchmark.results.size.to_s)
      end
    end

    it "identifies performance bottlenecks", tags: [TestTags::PERFORMANCE] do
      config = TestDataFactory.create_config("Bottleneck Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Bottleneck Test
        date: 2024-01-15
        layout: post
        ---

        # Bottleneck Test

        This tests bottleneck identification.
        MD

        File.write(File.join(content_dir, "bottleneck-test.md"), content_text)

        # Benchmark different operations
        benchmark = Lapis::PerformanceBenchmark.new

        # Benchmark individual operations
        benchmark.benchmark("content_loading") do
          Lapis::Content.load_all(content_dir)
        end

        benchmark.benchmark("template_rendering") do
          template_engine = Lapis::TemplateEngine.new(config)
          content = Lapis::Content.load_all(content_dir)
          content.each do |c|
            template_engine.render_all_formats(c)
          end
        end

        benchmark.benchmark("file_writing") do
          generator = Lapis::Generator.new(config)
          generator.build
        end

        # Identify bottlenecks
        fastest = benchmark.fastest_operation
        slowest = benchmark.slowest_operation

        fastest.should be_a(String)
        slowest.should be_a(String)

        Lapis::Logger.info("Bottleneck analysis completed",
          fastest_operation: fastest,
          slowest_operation: slowest)
      end
    end
  end
end
