require "spec"
require "file_utils"
require "../src/lapis/config"
require "../src/lapis/content"
require "../src/lapis/logger"
require "../src/lapis/memory_manager"
require "../src/lapis/performance_benchmark"
require "../src/lapis/exceptions"
require "../src/lapis/page_kinds"
require "../src/lapis/base_content"
require "../src/lapis/data_processor"
require "../src/lapis/functions"
require "../src/lapis/process_manager"
require "../src/lapis/parallel_processor"
require "../src/lapis/incremental_builder"
require "../src/lapis/analytics"
require "../src/lapis/file_watcher"
require "../src/lapis/generator"
require "../src/lapis/server"
require "../src/lapis/templates"
require "../src/lapis/partials"
require "../src/lapis/function_processor"
require "../src/lapis/live_reload"
require "../src/lapis/websocket_handler"
require "../src/lapis/cli"
require "../src/lapis/theme_manager"
require "../src/lapis/theme"

# Define VERSION constant for tests
module Lapis
  VERSION = "0.4.0"

  # Standard date formats used throughout the application
  DATE_FORMAT       = "%Y-%m-%d %H:%M:%S UTC"
  DATE_FORMAT_SHORT = "%Y-%m-%d"
  DATE_FORMAT_HUMAN = "%B %d, %Y"
end

# Test configuration and setup
Spec.before_suite do
  # Set up test environment
  ENV["LAPIS_LOG_LEVEL"] = "error" # Reduce log noise during tests
  ENV["LAPIS_TEST_MODE"] = "true"

  # Skip performance tests in development unless explicitly requested
  # Performance tests require --release flag to yield meaningful results
  if !ENV["LAPIS_INCLUDE_PERFORMANCE"]? && !ENV["CI"]?
    puts "Skipping performance tests (use LAPIS_INCLUDE_PERFORMANCE=1 to include them)"
  end

  # Clear any Process.on_terminate handlers that might interfere with tests
  Process.restore_interrupts!

  # Set up clean test output
  puts "\n🧪 Running Lapis Test Suite"
  puts "=" * 50
end

Spec.before_each do
  # Ensure Process.on_terminate is cleared before each test
  Process.restore_interrupts!
end

Spec.after_suite do
  # Clean up any test artifacts
  cleanup_test_files

  # Print clean test summary
  puts "\n" + "=" * 50
  puts "✅ Test Suite Complete"
  puts "=" * 50
end

# Test helper methods and setup
def sample_frontmatter
  {
    "title"       => YAML::Any.new("Sample Post"),
    "date"        => YAML::Any.new("2024-01-15"),
    "tags"        => YAML::Any.new(["crystal", "lapis"].map { |s| YAML::Any.new(s) }),
    "layout"      => YAML::Any.new("post"),
    "description" => YAML::Any.new("A sample post for testing"),
  }
end

def sample_markdown_content
  <<-MD
  # Sample Post

  This is a sample post for testing purposes.

  ## Features

  - Markdown parsing
  - Frontmatter support
  - Content generation

  ```crystal
  puts "Hello, Lapis!"
  ```
  MD
end

def create_temp_config
  Lapis::Config.new.tap do |config|
    config.title = "Test Site"
    config.output_dir = "test_output"
    config.debug = false
  end
end

def create_temp_content_file(content : String, frontmatter : Hash(String, YAML::Any) = sample_frontmatter)
  temp_file = File.tempfile("test_content", ".md")

  # Write frontmatter
  temp_file.print("---\n")
  frontmatter.each do |key, value|
    case value.raw
    when String
      temp_file.print("#{key}: #{value.as_s}\n")
    when Array
      temp_file.print("#{key}:\n")
      value.as_a.each do |item|
        temp_file.print("  - #{item.as_s}\n")
      end
    when Bool
      temp_file.print("#{key}: #{value.as_bool}\n")
    end
  end
  temp_file.print("---\n\n")
  temp_file.print(content)
  temp_file.flush

  temp_file.path
end

def create_temp_directory
  Dir.mkdir("test_temp") unless Dir.exists?("test_temp")
  "test_temp"
end

def cleanup_test_files
  # Clean up test output directory
  if Dir.exists?("test_output")
    FileUtils.rm_rf("test_output")
  end

  # Clean up test temp directory
  if Dir.exists?("test_temp")
    FileUtils.rm_rf("test_temp")
  end

  # Clean up shared build results
  SharedBuildResults.cleanup

  # Clean up any temp files
  Dir.glob("*.tmp").each do |file|
    File.delete(file) if File.exists?(file)
  end
end

def with_temp_directory(&)
  temp_dir = create_temp_directory
  begin
    yield temp_dir
  ensure
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end
end

def with_temp_file(content : String, &)
  temp_file = File.tempfile("test", ".md")
  temp_file.print(content)
  temp_file.flush

  begin
    yield temp_file.path
  ensure
    temp_file.close
    File.delete(temp_file.path) if File.exists?(temp_file.path)
  end
end

# Test data factories
class TestDataFactory
  def self.create_content(title : String = "Test Post",
                          date : String = "2024-01-15",
                          tags : Array(String) = ["test"],
                          layout : String = "post") : Hash(String, YAML::Any)
    {
      "title"       => YAML::Any.new(title),
      "date"        => YAML::Any.new(date),
      "tags"        => YAML::Any.new(tags.map { |s| YAML::Any.new(s) }),
      "layout"      => YAML::Any.new(layout),
      "description" => YAML::Any.new("Test description"),
    }
  end

  def self.create_config(title : String = "Test Site",
                         output_dir : String = "test_output",
                         debug : Bool = false) : Lapis::Config
    config = Lapis::Config.new
    config.title = title
    config.output_dir = output_dir
    config.debug = debug
    config
  end

  def self.create_content_item(title : String = "Test Post",
                               date : String = "2024-01-15",
                               tags : Array(String) = ["test"],
                               section : String = "posts") : Lapis::Content
    frontmatter = create_content(title, date, tags)
    Lapis::Content.new("content/#{section}/#{title.downcase.gsub(/\s+/, "-")}.md", frontmatter, "Content for #{title}")
  end
end

# Shared build results for performance tests
class SharedBuildResults
  @@shared_generator : Lapis::Generator? = nil
  @@shared_config : Lapis::Config? = nil
  @@shared_content_dir : String? = nil
  @@build_performed : Bool = false

  def self.shared_generator : Lapis::Generator
    @@shared_generator ||= begin
      config = create_shared_config
      generator = Lapis::Generator.new(config)
      generator
    end
  end

  def self.shared_config : Lapis::Config
    @@shared_config ||= create_shared_config
  end

  def self.shared_content_dir : String
    @@shared_content_dir ||= create_shared_content_dir
  end

  # Perform a single build once and reuse the result
  def self.perform_shared_build : Bool
    return true if @@build_performed

    generator = shared_generator
    generator.build
    @@build_performed = true
    true
  end

  # Mock build for tests that don't need real builds
  def self.mock_build : Bool
    # Just return true without actually building
    true
  end

  private def self.create_shared_config : Lapis::Config
    config = Lapis::Config.new
    config.title = "Shared Test Site"
    config.output_dir = "shared_test_output"
    config.debug = false
    config
  end

  private def self.create_shared_content_dir : String
    content_dir = "shared_test_content"
    Dir.mkdir_p(content_dir)

    # Create sample content
    content_text = <<-MD
    ---
    title: Shared Test Post
    date: 2024-01-15
    layout: post
    ---

    # Shared Test Post

    This is shared content for performance testing.
    MD

    File.write(File.join(content_dir, "shared-test.md"), content_text)
    content_dir
  end

  def self.cleanup
    @@shared_generator = nil
    @@shared_config = nil
    @@shared_content_dir = nil
    @@build_performed = false
    FileUtils.rm_rf("shared_test_output") if Dir.exists?("shared_test_output")
    FileUtils.rm_rf("shared_test_content") if Dir.exists?("shared_test_content")
  end
end

# Custom matchers for domain-specific assertions
module LapisMatchers
  def be_valid_content
    be_a(Lapis::Content)
  end

  def have_title(expected_title : String)
    have_title(expected_title)
  end

  def be_generated_file(file_path : String)
    File.exists?(file_path)
  end
end

# Include custom matchers
include LapisMatchers

# Test tags for organization
module TestTags
  FAST        = "fast"
  SLOW        = "slow"
  INTEGRATION = "integration"
  FUNCTIONAL  = "functional"
  PERFORMANCE = "performance"
  UNIT        = "unit"
end

# Helper method to check if performance tests should run
def should_run_performance_tests? : Bool
  ENV["LAPIS_INCLUDE_PERFORMANCE"]? == "1" || !ENV["CI"]?.nil?
end
