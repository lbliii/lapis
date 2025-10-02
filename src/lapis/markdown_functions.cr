require "html"
require "./function_registry"

module Lapis
  # Markdown processing functions
  module MarkdownFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:markdownify, 1) do |args|
        markdown = args[0]? || ""
        begin
          # This would use the Markd library for processing
          markdown # Placeholder - would need Markd integration
        rescue
          markdown
        end
      end

      FunctionRegistry.register_function(:"strip_html", 1) do |args|
        html = args[0]? || ""
        html.gsub(/<[^>]*>/, "")
      end

      FunctionRegistry.register_function(:"escape_html", 1) do |args|
        str = args[0]? || ""
        HTML.escape(str)
      end

      FunctionRegistry.register_function(:"unescape_html", 1) do |args|
        str = args[0]? || ""
        HTML.unescape(str)
      end
    end
  end
end
