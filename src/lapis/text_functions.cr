require "./function_registry"

module Lapis
  # Advanced text processing functions
  module TextFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:"word_count", 0) do |args|
        text = args[0]? || ""
        text.split.size.to_s
      end

      FunctionRegistry.register_function(:"reading_time", 0) do |args|
        text = args[0]? || ""
        words_per_minute = args[1]?.try(&.to_i?) || 200
        minutes = (text.split.size.to_f / words_per_minute).ceil
        minutes == 1 ? "1 min read" : "#{minutes} min read"
      end

      FunctionRegistry.register_function(:first, 2) do |args|
        text = args[0]? || ""
        count = args[1]?.try(&.to_i?) || 1
        text.split.first(count).join(" ")
      end

      FunctionRegistry.register_function(:last, 2) do |args|
        text = args[0]? || ""
        count = args[1]?.try(&.to_i?) || 1
        text.split.last(count).join(" ")
      end

      FunctionRegistry.register_function(:replace, 3) do |args|
        text = args[0]? || ""
        search = args[1]? || ""
        replace = args[2]? || ""
        text.gsub(search, replace)
      end

      FunctionRegistry.register_function(:remove, 2) do |args|
        text = args[0]? || ""
        search = args[1]? || ""
        text.gsub(search, "")
      end
    end
  end
end
