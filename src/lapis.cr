require "./lapis/*"

module Lapis
  VERSION = "0.4.0"
  # Build metadata constants following Crystal patterns
  BUILD_DATE   = {{ `date -u +"%Y-%m-%d"`.stringify }}
  BUILD_COMMIT = {{ `git rev-parse --short HEAD 2>/dev/null || echo "unknown"`.stringify }}
  DESCRIPTION  = "Lapis #{VERSION} [#{BUILD_COMMIT}] (#{BUILD_DATE})"

  # Standard date formats used throughout the application
  DATE_FORMAT       = "%Y-%m-%d %H:%M:%S UTC"
  DATE_FORMAT_SHORT = "%Y-%m-%d"
  DATE_FORMAT_HUMAN = "%B %d, %Y"
end

# Main entry point using Crystal's proper initialization
Crystal.main do
  if ARGV.size == 0
    puts Lapis::DESCRIPTION
    puts "Usage: lapis [command] [options]"
    puts ""
    puts "Commands:"
    puts "  init <name>    Create a new site"
    puts "  build          Build the site"
    puts "  serve          Start development server"
    puts "  new <type>     Create new content"
    puts "  version        Show version information"
    puts "  help           Show this help"
    exit
  end

  Lapis::CLI.new(ARGV).run
end
