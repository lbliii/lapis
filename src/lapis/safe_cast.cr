require "./logger"
require "./exceptions"

module Lapis
  # Safe type casting utilities to prevent TypeCastError exceptions
  module SafeCast
    # Safely cast an object to a specific type, returning nil if the cast fails
    def self.cast_or_nil(object, target_type : T.class) : T? forall T
      return nil if object.nil?
      object.is_a?(T) ? object.as(T) : nil
    end

    # Safely cast an object to a specific type, returning a default value if the cast fails
    def self.cast_or_default(object, target_type : T.class, default : T) : T forall T
      return default if object.nil?
      object.is_a?(T) ? object.as(T) : default
    end

    # Safely cast an object to a specific type, raising a Lapis TypeCastError if it fails
    def self.cast_or_raise(object, target_type : T.class, context : String = "") : T forall T
      return raise Lapis::TypeCastError.new("Cannot cast nil to #{T.name}", "Nil", T.name, "nil") if object.nil?
      if object.is_a?(T)
        Logger.type_cast_success("cast_or_raise", object.class.name, T.name, context: context)
        object.as(T)
      else
        Logger.type_cast_error("cast_or_raise", object.class.name, T.name, object.inspect, context: context)
        error_msg = "Failed to cast #{object.class.name} to #{T.name}"
        error_msg += " (#{context})" unless context.empty?
        raise Lapis::TypeCastError.new(
          error_msg,
          source_type: object.class.name,
          target_type: T.name,
          value: object.inspect
        )
      end
    end

    # Safely cast JSON::Any to a specific type
    def self.cast_json_any(object : JSON::Any, target_type : T.class) : T? forall T
      case target_type
      when String
        object.as_s? as T?
      when Int32
        object.as_i? as T?
      when Int64
        object.as_i64? as T?
      when Float32
        object.as_f? as T?
      when Float64
        object.as_f64? as T?
      when Bool
        object.as_bool? as T?
      when Array(String)
        object.as_a? as T?
      when Hash(String, JSON::Any)
        object.as_h? as T?
      else
        # For custom types, try direct casting
        begin
          object.as(T)
        rescue ::TypeCastError
          nil
        end
      end
    end

    # Safely cast YAML::Any to a specific type
    def self.cast_yaml_any(object : YAML::Any, target_type : T.class) : T? forall T
      case target_type
      when String
        object.as_s? as T?
      when Int32
        object.as_i? as T?
      when Int64
        object.as_i64? as T?
      when Float32
        object.as_f? as T?
      when Float64
        object.as_f64? as T?
      when Bool
        object.as_bool? as T?
      when Array(String)
        object.as_a? as T?
      when Hash(String, YAML::Any)
        object.as_h? as T?
      else
        # For custom types, try direct casting
        begin
          object.as(T)
        rescue ::TypeCastError
          nil
        end
      end
    end
  end
end