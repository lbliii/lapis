require "json"
require "yaml"
require "log"
require "./logger"
require "./exceptions"
require "./pretty_print_utils"

module Lapis
  # Enhanced JSON/YAML processing with validation
  class DataProcessor
    # Type-safe JSON parsing example
    class PostData
      include JSON::Serializable

      @[JSON::Field(emit_null: true)]
      property title : String

      @[JSON::Field(emit_null: true)]
      property count : Int32

      @[JSON::Field(emit_null: true)]
      property active : Bool

      @[JSON::Field(emit_null: true)]
      property tags : Array(String)?

      def initialize(@title : String, @count : Int32, @active : Bool, @tags : Array(String)? = nil)
      end
    end

    # Type-safe JSON parsing method
    def self.parse_json_typed(json_string : String) : PostData
      raise ArgumentError.new("JSON string cannot be empty") if json_string.strip.empty?
      Logger.debug("Parsing JSON with type safety", size: json_string.size.to_s)

      begin
        parsed = PostData.from_json(json_string)
        Logger.debug("Type-safe JSON parsed successfully")
        parsed
      rescue ex : JSON::ParseException
        Logger.error("Type-safe JSON parsing error", error: ex.message.to_s)
        raise ValidationError.new("Type-safe JSON parsing error: #{ex.message}", "json", json_string[0..100])
      rescue ex : ::TypeCastError
        Logger.error("Type cast error in JSON parsing", error: ex.message.to_s)
        raise Lapis::TypeCastError.new("Type cast error in JSON parsing: #{ex.message}", ex, "JSON", "PostData", json_string[0..100])
      rescue ex
        Logger.error("Unexpected type-safe JSON error", error: ex.message.to_s)
        raise ValidationError.new("Unexpected type-safe JSON error: #{ex.message}")
      end
    end

    # JSON processing
    def self.parse_json(json_string : String) : JSON::Any
      raise ArgumentError.new("JSON string cannot be empty") if json_string.strip.empty?
      Logger.debug("Parsing JSON", size: json_string.size.to_s)

      begin
        parsed = JSON.parse(json_string)
        Logger.debug("JSON parsed successfully")
        parsed
      rescue ex : JSON::ParseException
        Logger.error("JSON parsing error", error: ex.message.to_s)
        raise ValidationError.new("JSON parsing error: #{ex.message}", "json", json_string[0..100])
      rescue ex : ::TypeCastError
        Logger.error("Type cast error in JSON parsing", error: ex.message.to_s)
        raise Lapis::TypeCastError.new("Type cast error in JSON parsing: #{ex.message}", ex, "JSON", "JSON::Any", json_string[0..100])
      rescue ex
        Logger.error("Unexpected JSON error", error: ex.message.to_s)
        raise ValidationError.new("Unexpected JSON error: #{ex.message}")
      end
    end

    # YAML processing
    def self.parse_yaml(yaml_string : String) : YAML::Any
      raise ArgumentError.new("YAML string cannot be empty") if yaml_string.strip.empty?
      Logger.debug("Parsing YAML", size: yaml_string.size.to_s)

      begin
        parsed = YAML.parse(yaml_string)
        Logger.debug("YAML parsed successfully")
        parsed
      rescue ex : YAML::ParseException
        Logger.error("YAML parsing error", error: ex.message.to_s)
        raise ValidationError.new("YAML parsing error: #{ex.message}", "yaml", yaml_string[0..100])
      rescue ex : ::TypeCastError
        Logger.error("Type cast error in YAML parsing", error: ex.message.to_s)
        raise Lapis::TypeCastError.new("Type cast error in YAML parsing: #{ex.message}", ex, "YAML", "YAML::Any", yaml_string[0..100])
      rescue ex
        Logger.error("Unexpected YAML error", error: ex.message.to_s)
        raise ValidationError.new("Unexpected YAML error: #{ex.message}")
      end
    end

    # Safe JSON parsing with default value
    def self.parse_json_safe(json_string : String, default : JSON::Any? = nil) : JSON::Any?
      parse_json(json_string)
    rescue
      Logger.warn("JSON parsing failed, using default value")
      default
    end

    # Safe YAML parsing with default value
    def self.parse_yaml_safe(yaml_string : String, default : YAML::Any? = nil) : YAML::Any?
      parse_yaml(yaml_string)
    rescue
      Logger.warn("YAML parsing failed, using default value")
      default
    end

    # Convert JSON to YAML
    def self.json_to_yaml(json_data : JSON::Any) : String
      Logger.debug("Converting JSON to YAML")

      begin
        yaml_data = convert_json_to_yaml(json_data)
        Logger.debug("JSON to YAML conversion successful")
        yaml_data
      rescue ex
        Logger.error("JSON to YAML conversion failed", error: ex.message)
        raise ValidationError.new("JSON to YAML conversion failed: #{ex.message}")
      end
    end

    # Convert YAML to JSON
    def self.yaml_to_json(yaml_data : YAML::Any) : String
      Logger.debug("Converting YAML to JSON")

      begin
        json_data = convert_yaml_to_json(yaml_data)
        Logger.debug("YAML to JSON conversion successful")
        json_data
      rescue ex
        Logger.error("YAML to JSON conversion failed", error: ex.message)
        raise ValidationError.new("YAML to JSON conversion failed: #{ex.message}")
      end
    end

    # Pretty print JSON with enhanced formatting
    def self.pretty_json(data : JSON::Any) : String
      Logger.debug("Pretty printing JSON")

      begin
        # Use PrettyPrintUtils for enhanced formatting
        io = IO::Memory.new
        PrettyPrintUtils.format_data_structure(data, io, 80)
        pretty = io.to_s
        Logger.debug("JSON pretty printing successful")
        pretty
      rescue ex
        Logger.error("JSON pretty printing failed", error: ex.message)
        raise ValidationError.new("JSON pretty printing failed: #{ex.message}")
      end
    end

    # Pretty print YAML with enhanced formatting
    def self.pretty_yaml(data : YAML::Any) : String
      Logger.debug("Pretty printing YAML")

      begin
        # Use PrettyPrintUtils for enhanced formatting
        io = IO::Memory.new
        PrettyPrintUtils.format_data_structure(data, io, 80)
        pretty = io.to_s
        Logger.debug("YAML pretty printing successful")
        pretty
      rescue ex
        Logger.error("YAML pretty printing failed", error: ex.message)
        raise ValidationError.new("YAML pretty printing failed: #{ex.message}")
      end
    end

    # Enhanced pretty print with custom formatting options
    def self.pretty_print(data : JSON::Any | YAML::Any, width : Int32 = 80, indent : Int32 = 2) : String
      Logger.debug("Pretty printing data structure", width: width.to_s, indent: indent.to_s)

      begin
        io = IO::Memory.new
        PrettyPrintUtils.format_data_structure(data, io, width, indent)
        pretty = io.to_s
        Logger.debug("Data structure pretty printing successful")
        pretty
      rescue ex
        Logger.error("Data structure pretty printing failed", error: ex.message)
        raise ValidationError.new("Data structure pretty printing failed: #{ex.message}")
      end
    end

    # Pretty print with debug logging
    def self.debug_pretty_print(data : JSON::Any | YAML::Any, message : String = "Data structure", **context)
      Logger.debug_data(message, data, **context)
    end

    # Extract specific fields from JSON/YAML
    def self.extract_fields(data : JSON::Any | YAML::Any, fields : Array(String)) : Hash(String, JSON::Any | YAML::Any)
      Logger.debug("Extracting fields", fields: fields.join(", "))

      result = {} of String => (JSON::Any | YAML::Any)

      fields.each do |field|
        if data.is_a?(JSON::Any)
          if json_data = data[field]?
            result[field] = json_data
          end
        elsif data.is_a?(YAML::Any)
          if yaml_data = data[field]?
            result[field] = yaml_data
          end
        end
      end

      Logger.debug("Fields extracted", count: result.size.to_s)
      result
    end

    # Merge multiple JSON/YAML objects
    def self.merge_data(data_objects : Array(JSON::Any | YAML::Any)) : JSON::Any | YAML::Any
      Logger.debug("Merging data objects", count: data_objects.size.to_s)

      return JSON::Any.new(nil) if data_objects.empty?

      data_objects[1..].reduce(data_objects[0]) do |result, data|
        merge_single_data(result, data)
      end.tap { |merged| Logger.debug("Data merge completed", final_keys: merged.try(&.as_h?.keys) || [] of String) }
    end

    private def self.convert_json_to_yaml(json_data : JSON::Any) : String
      # Convert JSON::Any to YAML::Any and then to string
      yaml_data = convert_json_any_to_yaml_any(json_data)
      yaml_data.to_yaml
    end

    private def self.convert_yaml_to_json(yaml_data : YAML::Any) : String
      # Convert YAML::Any to JSON::Any and then to string
      json_data = convert_yaml_any_to_json_any(yaml_data)
      json_data.to_json
    end

    private def self.convert_json_any_to_yaml_any(json_data : JSON::Any) : YAML::Any
      case json_data.raw
      when Hash
        hash = {} of YAML::Any => YAML::Any
        json_data.as_h.each do |k, v|
          hash[YAML::Any.new(k)] = convert_json_any_to_yaml_any(v)
        end
        YAML::Any.new(hash)
      when Array
        array = [] of YAML::Any
        json_data.as_a.each do |v|
          array << convert_json_any_to_yaml_any(v)
        end
        YAML::Any.new(array)
      else
        # Convert primitive types explicitly for type safety
        case json_data.raw
        when String
          begin
            YAML::Any.new(json_data.raw.as(String))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to String, using to_s", value: json_data.raw.inspect)
            YAML::Any.new(json_data.raw.to_s)
          end
        when Int64
          begin
            YAML::Any.new(json_data.raw.as(Int64))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to Int64, using to_s", value: json_data.raw.inspect)
            YAML::Any.new(json_data.raw.to_s)
          end
        when Float64
          begin
            YAML::Any.new(json_data.raw.as(Float64))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to Float64, using to_s", value: json_data.raw.inspect)
            YAML::Any.new(json_data.raw.to_s)
          end
        when Bool
          begin
            YAML::Any.new(json_data.raw.as(Bool))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to Bool, using to_s", value: json_data.raw.inspect)
            YAML::Any.new(json_data.raw.to_s)
          end
        when Nil
          YAML::Any.new(nil)
        when Array(JSON::Any)
          # This should not happen as arrays are handled above
          YAML::Any.new(json_data.raw.to_s)
        when Hash(String, JSON::Any)
          # This should not happen as hashes are handled above
          YAML::Any.new(json_data.raw.to_s)
        else
          YAML::Any.new(json_data.raw.to_s)
        end
      end
    end

    private def self.convert_yaml_any_to_json_any(yaml_data : YAML::Any) : JSON::Any
      case yaml_data.raw
      when Hash
        hash = {} of String => JSON::Any
        yaml_data.as_h.each do |k, v|
          hash[k.as_s] = convert_yaml_any_to_json_any(v)
        end
        JSON::Any.new(hash)
      when Array
        array = [] of JSON::Any
        yaml_data.as_a.each do |v|
          array << convert_yaml_any_to_json_any(v)
        end
        JSON::Any.new(array)
      else
        # Convert primitive types explicitly for type safety
        case yaml_data.raw
        when String
          begin
            JSON::Any.new(yaml_data.raw.as(String))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to String, using to_s", value: yaml_data.raw.inspect)
            JSON::Any.new(yaml_data.raw.to_s)
          end
        when Int64
          begin
            JSON::Any.new(yaml_data.raw.as(Int64))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to Int64, using to_s", value: yaml_data.raw.inspect)
            JSON::Any.new(yaml_data.raw.to_s)
          end
        when Float64
          begin
            JSON::Any.new(yaml_data.raw.as(Float64))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to Float64, using to_s", value: yaml_data.raw.inspect)
            JSON::Any.new(yaml_data.raw.to_s)
          end
        when Bool
          begin
            JSON::Any.new(yaml_data.raw.as(Bool))
          rescue ::TypeCastError
            Logger.warn("Failed to cast to Bool, using to_s", value: yaml_data.raw.inspect)
            JSON::Any.new(yaml_data.raw.to_s)
          end
        when Nil
          JSON::Any.new(nil)
        else
          JSON::Any.new(yaml_data.raw.to_s)
        end
      end
    end

    private def self.merge_single_data(base : JSON::Any | YAML::Any, other : JSON::Any | YAML::Any) : JSON::Any | YAML::Any
      # Simple merge implementation - can be enhanced
      if base.is_a?(JSON::Any) && other.is_a?(JSON::Any)
        if base.as_h? && other.as_h?
          merged = base.as_h.dup
          other.as_h.each do |k, v|
            merged[k] = v
          end
          JSON::Any.new(merged)
        else
          other
        end
      elsif base.is_a?(YAML::Any) && other.is_a?(YAML::Any)
        if base.as_h? && other.as_h?
          merged = base.as_h.dup
          other.as_h.each do |k, v|
            merged[k] = v
          end
          YAML::Any.new(merged)
        else
          other
        end
      else
        other
      end
    end
  end
end
