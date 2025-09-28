require "./spec_helper"

# Main test suite - runs all tests
# Individual test files are organized in subdirectories:
# - spec/unit/ - Unit tests for individual classes
# - spec/integration/ - Integration tests for component interactions
# - spec/functional/ - End-to-end workflow tests
# - spec/performance/ - Performance and benchmark tests

describe Lapis do
  it "has correct version", tags: [TestTags::FAST, TestTags::UNIT] do
    Lapis::VERSION.should eq("0.3.0")
  end
end

describe Lapis::Config do
  it "loads with defaults", tags: [TestTags::FAST, TestTags::UNIT] do
    config = Lapis::Config.new
    config.title.should eq("Lapis Site")
    config.port.should eq(3000)
    config.output_dir.should eq("public")
  end

  it "validates configuration", tags: [TestTags::FAST, TestTags::UNIT] do
    config = Lapis::Config.new
    config.output_dir = ""
    config.validate
    config.output_dir.should eq("public")
  end

  it "supports debug mode", tags: [TestTags::FAST, TestTags::UNIT] do
    config = Lapis::Config.new
    config.debug = true
    config.debug.should be_true
  end

  it "supports logging configuration", tags: [TestTags::FAST, TestTags::UNIT] do
    config = Lapis::Config.new
    config.log_file = "test.log"
    config.log_level = "debug"

    config.log_file.should eq("test.log")
    config.log_level.should eq("debug")
  end
end

# Include all test files
require "./unit/logger_spec"
require "./unit/memory_manager_spec"
require "./unit/content_spec"
require "./unit/performance_benchmark_spec"
require "./unit/config_spec"
require "./unit/data_processor_spec"
require "./unit/functions_spec"
require "./unit/process_manager_spec"
require "./unit/exceptions_spec"

# Integration tests
require "./integration/generator_spec"
require "./integration/server_spec"
require "./integration/template_engine_spec"

# Functional tests
require "./functional/build_workflow_spec"
require "./functional/cli_spec"

# Performance tests
require "./performance/memory_usage_spec"
require "./performance/build_performance_spec"
