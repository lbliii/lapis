require "./function_registry"

module Lapis
  # Array manipulation functions with modern Crystal Array methods
  module ArrayFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:len, 1) do |args|
        args[0] ? args[0].size.to_s : "0"
      end

      # Array manipulation functions
      FunctionRegistry.register_function(:uniq, 1) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        # Use Set directly to avoid intermediate array creation
        seen = Set(String).new
        unique_items = items.select { |item| seen.add?(item) }
        unique_items.join(",")
      end

      FunctionRegistry.register_function(:uniq_by, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        key_func = args[1]? || "length"
        # Use Set directly to avoid intermediate array creation
        seen = Set(String).new
        unique_items = items.select { |item| seen.add?(item) }
        unique_items.join(",")
      end

      FunctionRegistry.register_function(:sample, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        count = args[1]?.try(&.to_i?) || 1
        next "" if items.empty?
        # Bounds checking: ensure count doesn't exceed items.size
        safe_count = Math.min(count, items.size)
        items.sample(safe_count).join(",")
      end

      FunctionRegistry.register_function(:shuffle, 1) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        items.shuffle.join(",")
      end

      FunctionRegistry.register_function(:rotate, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        n = args[1]?.try(&.to_i?) || 1
        items.rotate(n).join(",")
      end

      FunctionRegistry.register_function(:array_reverse, 1) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        items.reverse.join(",")
      end

      # Slice-based array functions for zero-copy operations
      FunctionRegistry.register_function(:slice_uniq, 1) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        next "" if items.empty?
        # For now, use regular array operations - slice ops need more work
        items.uniq.join(",")
      end

      FunctionRegistry.register_function(:slice_sample, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        count = args[1]?.try(&.to_i?) || 1
        next "" if items.empty?
        # Bounds checking: ensure count doesn't exceed items.size
        safe_count = Math.min(count, items.size)
        # For now, use regular array operations - slice ops need more work
        items.sample(safe_count).join(",")
      end

      FunctionRegistry.register_function(:slice_shuffle, 1) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        next "" if items.empty?
        # For now, use regular array operations - slice ops need more work
        items.shuffle.join(",")
      end

      FunctionRegistry.register_function(:slice_rotate, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        n = args[1]?.try(&.to_i?) || 1
        next "" if items.empty?
        # For now, use regular array operations - slice ops need more work
        items.rotate(n).join(",")
      end

      FunctionRegistry.register_function(:slice_reverse, 1) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        next "" if items.empty?
        # For now, use regular array operations - slice ops need more work
        items.reverse.join(",")
      end

      FunctionRegistry.register_function(:sort_by_length, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        reverse = args[1]? == "true"
        sorted = items.sort_by(&.size)
        reverse ? sorted.reverse.join(",") : sorted.join(",")
      end

      FunctionRegistry.register_function(:partition, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        condition = args[1]? || "length"
        case condition
        when "length"
          long, short = items.partition { |item| item.size > 5 }
          "long:#{long.join(",")}|short:#{short.join(",")}"
        when "empty"
          non_empty, empty = items.partition { |item| !item.strip.empty? }
          "non_empty:#{non_empty.join(",")}|empty:#{empty.join(",")}"
        else
          items.join(",")
        end
      end

      FunctionRegistry.register_function(:compact, 1) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        items.compact.join(",")
      end

      FunctionRegistry.register_function(:chunk, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        key_func = args[1]? || "length"
        case key_func
        when "length"
          chunks = items.group_by(&.size)
          chunks.map { |key, group| "#{key}:#{group.join(",")}" }.join("|")
        when "first_char"
          chunks = items.group_by { |item| item.empty? ? "?" : item[0].to_s }
          chunks.map { |key, group| "#{key}:#{group.join(",")}" }.join("|")
        else
          items.join(",")
        end
      end

      FunctionRegistry.register_function(:index, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        search_item = args[1]? || ""
        if idx = items.index(search_item)
          idx.to_s
        else
          "-1"
        end
      end

      FunctionRegistry.register_function(:rindex, 2) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        search_item = args[1]? || ""
        if idx = items.rindex(search_item)
          idx.to_s
        else
          "-1"
        end
      end

      FunctionRegistry.register_function(:"array_truncate", 3) do |args|
        items = args[0]?.try(&.split(",")) || [] of String
        start_idx = args[1]?.try(&.to_i?) || 0
        end_idx = args[2]?.try(&.to_i?) || items.size
        next "" if items.empty?

        # Use Range for validation
        range = 0...items.size
        next "" unless range.includes?(start_idx)

        safe_end_idx = Math.min(end_idx, items.size)
        items[start_idx...safe_end_idx].join(",")
      end
    end
  end
end
