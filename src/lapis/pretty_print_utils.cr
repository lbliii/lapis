require "pretty_print"

module Lapis
  # Utility module for consistent pretty printing across the project
  module PrettyPrintUtils
    extend self

    # Default width for pretty printing
    DEFAULT_WIDTH  = 80
    DEFAULT_INDENT =  2

    # Pretty print any object to an IO
    def format(obj, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH, indent : Int32 = 0)
      PrettyPrint.format(obj, io, width, "\n", indent)
    end

    # Pretty print with a block for custom formatting
    def format(io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH, indent : Int32 = 0, &)
      PrettyPrint.format(io, width, "\n", indent) do |pp|
        yield pp
      end
    end

    # Pretty print configuration data (Hash) with consistent styling
    def format_config_data(config_data : Hash, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      pp = PrettyPrint.new(io, width)
      pp.group do
        pp.text "Configuration:"
        pp.breakable
        pp.group do
          config_data.each_with_index do |(key, value), index|
            pp.text "#{key}:"
            pp.nest do
              pp.breakable
              format_value(value, pp)
            end
            pp.comma unless index == config_data.size - 1
            pp.breakable unless index == config_data.size - 1
          end
        end
      end
      pp.flush
    end

    # Pretty print configuration objects with consistent styling
    def format_config(config : Config, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      pp = PrettyPrint.new(io, width)
      pp.group do
        pp.text "Configuration:"
        pp.breakable
        pp.group do
          pp.text "Site:"
          pp.nest do
            pp.breakable
            pp.text "title: #{config.title.inspect}"
            pp.comma
            pp.text "base_url: #{config.baseurl.inspect}"
            pp.comma
            pp.text "theme: #{config.theme.inspect}"
          end
          pp.breakable
          pp.text "Build:"
          pp.nest do
            pp.breakable
            pp.text "incremental: #{config.build_config.incremental?}"
            pp.comma
            pp.text "parallel: #{config.build_config.parallel?}"
            pp.comma
            pp.text "max_workers: #{config.build_config.max_workers}"
            pp.comma
            pp.text "cache_dir: #{config.build_config.cache_dir.inspect}"
          end
          pp.breakable
          pp.text "Server:"
          pp.nest do
            pp.breakable
            pp.text "host: #{config.host.inspect}"
            pp.comma
            pp.text "port: #{config.port}"
            pp.comma
            pp.text "debug: #{config.debug}"
          end
        end
      end
      pp.flush
    end

    # Pretty print content objects with key information
    def format_content(content : Content, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      pp = PrettyPrint.new(io, width)
      pp.group do
        pp.text "Content:"
        pp.breakable
        pp.group do
          pp.text "title: #{content.title.inspect}"
          pp.comma
          pp.text "url: #{content.url.inspect}"
          pp.comma
          pp.text "kind: #{content.kind}"
          pp.comma
          pp.text "date: #{content.date}"
          pp.comma
          pp.text "draft: #{content.draft?}"
          if content.tags.any?
            pp.breakable
            pp.text "tags:"
            pp.nest do
              pp.breakable
              pp.list("[", content.tags, "]") do |tag|
                pp.text tag.inspect
              end
            end
          end
        end
      end
      pp.flush
    end

    # Pretty print error context for debugging
    def format_error_context(context : Hash, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      pp = PrettyPrint.new(io, width)
      pp.group do
        pp.text "Error Context:"
        pp.breakable
        pp.group do
          context.each_with_index do |(key, value), index|
            pp.text "#{key}:"
            pp.nest do
              pp.breakable
              format_value(value, pp)
            end
            pp.comma unless index == context.size - 1
            pp.breakable unless index == context.size - 1
          end
        end
      end
      pp.flush
    end

    # Pretty print data structures (JSON/YAML)
    def format_data_structure(data : JSON::Any | YAML::Any, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      case data
      when JSON::Any
        format_json_structure(data, io, width)
      when YAML::Any
        format_yaml_structure(data, io, width)
      end
    end

    # Pretty print build analytics
    def format_analytics(analytics : Hash, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      pp = PrettyPrint.new(io, width)
      pp.group do
        pp.text "Build Analytics:"
        pp.breakable
        pp.group do
          analytics.each_with_index do |(key, value), index|
            pp.text "#{key}:"
            pp.nest do
              pp.breakable
              case value
              when Int32, Int64
                pp.text value.to_s
              when Float32, Float64
                pp.text "%.2f" % value
              when String
                pp.text value.inspect
              else
                pp.text value.inspect
              end
            end
            pp.comma unless index == analytics.size - 1
            pp.breakable unless index == analytics.size - 1
          end
        end
      end
      pp.flush
    end

    # Pretty print CLI help with structured formatting
    def format_help_section(title : String, content : String, io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      pp = PrettyPrint.new(io, width)
      pp.group do
        pp.text title.colorize(:cyan).bold.to_s
        pp.breakable
        pp.group do
          content.lines.each_with_index do |line, index|
            pp.text line
            pp.breakable unless index == content.lines.size - 1
          end
        end
        pp.breakable
        pp.breakable
      end
      pp.flush
    end

    # Format output format configuration
    def format_output_formats(formats : Hash(String, OutputFormat), io : IO = STDOUT, width : Int32 = DEFAULT_WIDTH)
      pp = PrettyPrint.new(io, width)
      pp.group do
        pp.text "Output Formats:"
        pp.breakable
        pp.group do
          formats.each_with_index do |(name, format), index|
            pp.text "#{name}:"
            pp.nest do
              pp.breakable
              pp.text "media_type: #{format.media_type}"
              pp.comma
              pp.text "extension: #{format.extension.inspect}"
              pp.comma
              pp.text "is_html: #{format.is_html}"
              pp.comma
              pp.text "weight: #{format.weight}"
            end
            pp.comma unless index == formats.size - 1
            pp.breakable unless index == formats.size - 1
          end
        end
      end
      pp.flush
    end

    private def format_json_structure(data : JSON::Any, io : IO, width : Int32)
      pp = PrettyPrint.new(io, width)
      format_json_value(data, pp)
      pp.flush
    end

    private def format_yaml_structure(data : YAML::Any, io : IO, width : Int32)
      pp = PrettyPrint.new(io, width)
      format_yaml_value(data, pp)
      pp.flush
    end

    private def format_json_value(json : JSON::Any, pp : PrettyPrint)
      case json.raw
      when Hash
        pp.text "{"
        pp.nest do
          json.as_h.each_with_index do |(key, value), index|
            pp.breakable
            pp.text "#{key.inspect}:"
            pp.text " "
            format_json_value(value, pp)
            pp.text "," unless index == json.as_h.size - 1
          end
        end
        pp.breakable
        pp.text "}"
      when Array
        pp.text "["
        pp.nest do
          json.as_a.each_with_index do |value, index|
            pp.breakable
            format_json_value(value, pp)
            pp.text "," unless index == json.as_a.size - 1
          end
        end
        pp.breakable
        pp.text "]"
      else
        pp.text json.raw.inspect
      end
    end

    private def format_yaml_value(yaml : YAML::Any, pp : PrettyPrint)
      case yaml.raw
      when Hash
        pp.text "{"
        pp.nest do
          yaml.as_h.each_with_index do |(key, value), index|
            pp.breakable
            pp.text "#{key.inspect}:"
            pp.text " "
            format_yaml_value(value, pp)
            pp.text "," unless index == yaml.as_h.size - 1
          end
        end
        pp.breakable
        pp.text "}"
      when Array
        pp.text "["
        pp.nest do
          yaml.as_a.each_with_index do |value, index|
            pp.breakable
            format_yaml_value(value, pp)
            pp.text "," unless index == yaml.as_a.size - 1
          end
        end
        pp.breakable
        pp.text "]"
      else
        pp.text yaml.raw.inspect
      end
    end

    private def format_value(value, pp : PrettyPrint)
      case value
      when String
        pp.text value.inspect
      when Int32, Int64, Float32, Float64, Bool
        pp.text value.to_s
      when Array
        pp.list("[", value, "]") do |item|
          format_value(item, pp)
        end
      when Hash
        pp.text "{"
        pp.nest do
          value.each_with_index do |(key, val), index|
            pp.breakable
            pp.text "#{key.inspect}:"
            pp.text " "
            format_value(val, pp)
            pp.text "," unless index == value.size - 1
          end
        end
        pp.breakable
        pp.text "}"
      else
        pp.text value.inspect
      end
    end
  end
end
