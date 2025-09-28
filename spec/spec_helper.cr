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
end

Spec.after_suite do
  # Clean up any test artifacts
  cleanup_test_files
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

  def self.create_site_with_content(content_count : Int32 = 3) : Array(Lapis::Content)
    content = [] of Lapis::Content

    content_count.times do |i|
      frontmatter = create_content("Post #{i + 1}")
      body = "Content for post #{i + 1}"

      content << Lapis::Content.new("content/posts/post-#{i + 1}.md", frontmatter, body)
    end

    content
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
