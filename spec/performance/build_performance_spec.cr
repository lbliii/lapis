require "../spec_helper"

describe "Build Performance" do
  if should_run_performance_tests?
    describe "benchmarking" do
      it "benchmarks build operations", tags: [TestTags::PERFORMANCE] do
        # Use shared build results to avoid multiple builds
        config = SharedBuildResults.shared_config
        content_dir = SharedBuildResults.shared_content_dir

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

        # Benchmark full build (only one build total across all tests)
        build_result = benchmark.benchmark("full_build") do
          SharedBuildResults.perform_shared_build
          nil
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

      it "compares different build strategies", tags: [TestTags::PERFORMANCE] do
        # Use shared config to avoid creating new content
        config = SharedBuildResults.shared_config

        # Compare different build strategies using mock builds
        benchmark = Lapis::PerformanceBenchmark.new

        operations = {
          "sequential" => -> {
            config.build_config.parallel = false
            # Mock the build instead of actually building
            SharedBuildResults.mock_build
            nil
          },
          "parallel" => -> {
            config.build_config.parallel = true
            # Mock the build instead of actually building
            SharedBuildResults.mock_build
            nil
          },
        }

        comparison_result = benchmark.compare("build_strategies", operations)
        comparison_result.should be_a(Benchmark::BM::Job)

        Lapis::Logger.info("Build strategy comparison completed")
      end

      it "benchmarks memory-aware operations", tags: [TestTags::PERFORMANCE] do
        # Use shared config to avoid creating new content
        config = SharedBuildResults.shared_config

        # Benchmark with memory monitoring using mock build
        benchmark = Lapis::PerformanceBenchmark.new

        result = benchmark.benchmark_with_memory("memory_aware_build") do
          SharedBuildResults.mock_build
          nil
        end

        result.should be_a(Benchmark::BM::Tms)

        Lapis::Logger.info("Memory-aware benchmark completed")
      end
    end

    describe "performance monitoring" do
      it "monitors build performance over time", tags: [TestTags::PERFORMANCE] do
        # Use shared config to avoid creating new content
        config = SharedBuildResults.shared_config

        # Monitor multiple builds using mock builds
        benchmark = Lapis::PerformanceBenchmark.new

        3.times do |i|
          result = benchmark.benchmark("build_#{i + 1}") do
            SharedBuildResults.mock_build
            nil
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

      it "identifies performance bottlenecks", tags: [TestTags::PERFORMANCE] do
        # Use shared config to avoid creating new content
        config = SharedBuildResults.shared_config
        content_dir = SharedBuildResults.shared_content_dir

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
          SharedBuildResults.mock_build
          nil
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
  else
    pending "Performance tests skipped (use LAPIS_INCLUDE_PERFORMANCE=1 to run)"
  end
end
