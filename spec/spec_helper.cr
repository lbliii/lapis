require "spec"
require "../src/lapis"

# Test helper methods and setup go here

def sample_frontmatter
  {
    "title" => YAML::Any.new("Sample Post"),
    "date" => YAML::Any.new("2024-01-15"),
    "tags" => YAML::Any.new(["crystal", "lapis"].map { |s| YAML::Any.new(s) }),
    "layout" => YAML::Any.new("post"),
    "description" => YAML::Any.new("A sample post for testing")
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
  end
end