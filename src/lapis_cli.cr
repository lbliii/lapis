require "./lapis"

# CLI entry point - this file should be used as the main for the executable
# This separates the CLI from the library, allowing lapis.cr to be required
# for testing and other purposes without triggering the CLI

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

