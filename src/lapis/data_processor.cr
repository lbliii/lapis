require "json"
require "yaml"
require "log"
require "./logger"
require "./exceptions"

module Lapis
  # Enhanced JSON/YAML processing with validation
  class DataProcessor
    # JSON processing with validation
    def self.parse_json(json_string : String, schema : JSON::Schema? = nil) : JSON::Any
      Logger.debug("Parsing JSON", size: json_string.size.to_s)
      
      begin
        parsed = JSON.parse(json_string)
        
        # Validate against schema if provided
        if schema
          validate_json_schema(parsed, schema)
        end
        
        Logger.debug("JSON parsed successfully")
        parsed
      rescue ex : JSON::ParseException
        Logger.error("JSON parsing error", error: ex.message, line: ex.line_number.to_s)
        raise ValidationError.new("JSON parsing error: #{ex.message}", "json", json_string[0..100])
      rescue ex
        Logger.error("Unexpected JSON error", error: ex.message)
        raise ValidationError.new("Unexpected JSON error: #{ex.message}")
      end
    end

    # YAML processing with validation
    def self.parse_yaml(yaml_string : String, schema : YAML::Schema? = nil) : YAML::Any
      Logger.debug("Parsing YAML", size: yaml_string.size.to_s)
      
      begin
        parsed = YAML.parse(yaml_string)
        
        # Validate against schema if provided
        if schema
          validate_yaml_schema(parsed, schema)
        end
        
        Logger.debug("YAML parsed successfully")
        parsed
      rescue ex : YAML::ParseException
        Logger.error("YAML parsing error", error: ex.message, line: ex.line_number.to_s)
        raise ValidationError.new("YAML parsing error: #{ex.message}", "yaml", yaml_string[0..100])
      rescue ex
        Logger.error("Unexpected YAML error", error: ex.message)
        raise ValidationError.new("Unexpected YAML error: #{ex.message}")
      end
    end

    # Safe JSON parsing with default value
    def self.parse_json_safe(json_string : String, default : JSON::Any = JSON::Any.new(nil)) : JSON::Any
      parse_json(json_string)
    rescue
      Logger.warn("JSON parsing failed, using default value")
      default
    end

    # Safe YAML parsing with default value
    def self.parse_yaml_safe(yaml_string : String, default : YAML::Any = YAML::Any.new(nil)) : YAML::Any
      parse_yaml(yaml_string)
    rescue
      Logger.warn("YAML parsing failed, using default value")
      default
    end

    # Validate JSON against a schema
    def self.validate_json_schema(data : JSON::Any, schema : JSON::Schema)
      Logger.debug("Validating JSON against schema")
      
      # Basic validation - can be extended with more sophisticated schema validation
      case schema
      when JSON::Schema::Object
        validate_json_object(data, schema)
      when JSON::Schema::Array
        validate_json_array(data, schema)
      when JSON::Schema::String
        validate_json_string(data, schema)
      when JSON::Schema::Number
        validate_json_number(data, schema)
      when JSON::Schema::Boolean
        validate_json_boolean(data, schema)
      else
        Logger.warn("Unknown JSON schema type")
      end
    end

    # Validate YAML against a schema
    def self.validate_yaml_schema(data : YAML::Any, schema : YAML::Schema)
      Logger.debug("Validating YAML against schema")
      
      # Basic validation - can be extended with more sophisticated schema validation
      case schema
      when YAML::Schema::Core
        validate_yaml_core(data, schema)
      else
        Logger.warn("Unknown YAML schema type")
      end
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

    # Pretty print JSON
    def self.pretty_json(data : JSON::Any) : String
      Logger.debug("Pretty printing JSON")
      
      begin
        pretty = data.to_pretty_json
        Logger.debug("JSON pretty printing successful")
        pretty
      rescue ex
        Logger.error("JSON pretty printing failed", error: ex.message)
        raise ValidationError.new("JSON pretty printing failed: #{ex.message}")
      end
    end

    # Pretty print YAML
    def self.pretty_yaml(data : YAML::Any) : String
      Logger.debug("Pretty printing YAML")
      
      begin
        pretty = data.to_yaml
        Logger.debug("YAML pretty printing successful")
        pretty
      rescue ex
        Logger.error("YAML pretty printing failed", error: ex.message)
        raise ValidationError.new("YAML pretty printing failed: #{ex.message}")
      end
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
      
      result = data_objects[0]
      
      data_objects[1..].each do |data|
        result = merge_single_data(result, data)
      end
      
      Logger.debug("Data merge completed")
      result
    end

    private def self.validate_json_object(data : JSON::Any, schema : JSON::Schema::Object)
      unless data.as_h?
        raise ValidationError.new("Expected JSON object, got #{data.raw.class}")
      end
    end

    private def self.validate_json_array(data : JSON::Any, schema : JSON::Schema::Array)
      unless data.as_a?
        raise ValidationError.new("Expected JSON array, got #{data.raw.class}")
      end
    end

    private def self.validate_json_string(data : JSON::Any, schema : JSON::Schema::String)
      unless data.as_s?
        raise ValidationError.new("Expected JSON string, got #{data.raw.class}")
      end
    end

    private def self.validate_json_number(data : JSON::Any, schema : JSON::Schema::Number)
      unless data.as_f? || data.as_i?
        raise ValidationError.new("Expected JSON number, got #{data.raw.class}")
      end
    end

    private def self.validate_json_boolean(data : JSON::Any, schema : JSON::Schema::Boolean)
      unless data.as_bool?
        raise ValidationError.new("Expected JSON boolean, got #{data.raw.class}")
      end
    end

    private def self.validate_yaml_core(data : YAML::Any, schema : YAML::Schema::Core)
      # Basic YAML core validation
      Logger.debug("Validating YAML core schema")
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
        hash = {} of String => YAML::Any
        json_data.as_h.each do |k, v|
          hash[k] = convert_json_any_to_yaml_any(v)
        end
        YAML::Any.new(hash)
      when Array
        array = [] of YAML::Any
        json_data.as_a.each do |v|
          array << convert_json_any_to_yaml_any(v)
        end
        YAML::Any.new(array)
      else
        YAML::Any.new(json_data.raw)
      end
    end

    private def self.convert_yaml_any_to_json_any(yaml_data : YAML::Any) : JSON::Any
      case yaml_data.raw
      when Hash
        hash = {} of String => JSON::Any
        yaml_data.as_h.each do |k, v|
          hash[k] = convert_yaml_any_to_json_any(v)
        end
        JSON::Any.new(hash)
      when Array
        array = [] of JSON::Any
        yaml_data.as_a.each do |v|
          array << convert_yaml_any_to_json_any(v)
        end
        JSON::Any.new(array)
      else
        JSON::Any.new(yaml_data.raw)
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
