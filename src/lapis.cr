require "./lapis/*"

module Lapis
  VERSION = "0.4.0"

  # Standard date formats used throughout the application
  DATE_FORMAT       = "%Y-%m-%d %H:%M:%S UTC"
  DATE_FORMAT_SHORT = "%Y-%m-%d"
  DATE_FORMAT_HUMAN = "%B %d, %Y"
end

# Main entry point
if ARGV.size == 0
  puts "Lapis static site generator v#{Lapis::VERSION}"
  puts "Usage: lapis [command] [options]"
  puts ""
  puts "Commands:"
  puts "  init <name>    Create a new site"
  puts "  build          Build the site"
  puts "  serve          Start development server"
  puts "  new <type>     Create new content"
  puts "  help           Show this help"
  exit
end

Lapis::CLI.new(ARGV).run
