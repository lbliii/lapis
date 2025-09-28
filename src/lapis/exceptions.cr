module Lapis
  # Base exception for all Lapis-specific errors
  class LapisError < Exception
    getter context : Hash(String, String)

    def initialize(message : String, @context : Hash(String, String) = {} of String => String)
      super(message)
    end

    def initialize(message : String, cause : Exception, @context : Hash(String, String) = {} of String => String)
      super(message, cause)
    end
  end

  # Configuration-related errors
  class ConfigError < LapisError
    def initialize(message : String, file_path : String? = nil)
      context = file_path ? {"file" => file_path} : {} of String => String
      super(message, context)
    end
  end

  # Content processing errors
  class ContentError < LapisError
    def initialize(message : String, file_path : String? = nil, line_number : Int32? = nil)
      context = {} of String => String
      context["file"] = file_path if file_path
      context["line"] = line_number.to_s if line_number
      super(message, context)
    end
  end

  # Template processing errors
  class TemplateError < LapisError
    def initialize(message : String, template_path : String? = nil, line_number : Int32? = nil)
      context = {} of String => String
      context["template"] = template_path if template_path
      context["line"] = line_number.to_s if line_number
      super(message, context)
    end
  end

  # Build process errors
  class BuildError < LapisError
    def initialize(message : String, phase : String? = nil)
      context = phase ? {"phase" => phase} : {} of String => String
      super(message, context)
    end
  end

  # Server-related errors
  class ServerError < LapisError
    def initialize(message : String, port : Int32? = nil, host : String? = nil)
      context = {} of String => String
      context["port"] = port.to_s if port
      context["host"] = host if host
      super(message, context)
    end
  end

  # File system errors
  class FileSystemError < LapisError
    def initialize(message : String, file_path : String? = nil, operation : String? = nil)
      context = {} of String => String
      context["file"] = file_path if file_path
      context["operation"] = operation if operation
      super(message, context)
    end
  end

  # WebSocket errors
  class WebSocketError < LapisError
    def initialize(message : String, connection_id : String? = nil)
      context = connection_id ? {"connection" => connection_id} : {} of String => String
      super(message, context)
    end
  end

  # Asset processing errors
  class AssetError < LapisError
    def initialize(message : String, asset_path : String? = nil, asset_type : String? = nil)
      context = {} of String => String
      context["asset"] = asset_path if asset_path
      context["type"] = asset_type if asset_type
      super(message, context)
    end
  end

  # Validation errors
  class ValidationError < LapisError
    def initialize(message : String, field : String? = nil, value : String? = nil)
      context = {} of String => String
      context["field"] = field if field
      context["value"] = value if value
      super(message, context)
    end
  end

  # Process execution errors
  class ProcessError < LapisError
    def initialize(message : String, command : String? = nil, exit_code : Int32? = nil)
      context = {} of String => String
      context["command"] = command if command
      context["exit_code"] = exit_code.to_s if exit_code
      super(message, context)
    end
  end
end
