require "uri"
require "json"
require "./function_registry"

module Lapis
  # URL and URI manipulation functions with complete URI-based implementation
  module UrlFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:urlize, 1) do |args|
        str = args[0] || ""
        str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      end

      FunctionRegistry.register_function(:"relative_url", 2) do |args|
        url = args[0] || ""
        base = args[1]? || ""
        next url if url.starts_with?("http")

        base_uri = URI.parse(base)
        target_uri = URI.parse(url)
        base_uri.relativize(target_uri).to_s
      end

      FunctionRegistry.register_function(:"absolute_url", 2) do |args|
        url = args[0] || ""
        base = args[1]? || ""
        next url if url.starts_with?("http")

        base_uri = URI.parse(base)
        target_uri = URI.parse(url)
        base_uri.resolve(target_uri).to_s
      end

      FunctionRegistry.register_function(:"url_encode", 1) do |args|
        str = args[0] || ""
        URI.encode_path(str)
      end

      FunctionRegistry.register_function(:"url_decode", 1) do |args|
        str = args[0] || ""
        URI.decode(str)
      end

      # URI-based functions
      FunctionRegistry.register_function(:"url_normalize", 1) do |args|
        url = args[0] || ""
        URI.parse(url).normalize.to_s
      end

      FunctionRegistry.register_function(:"url_scheme", 1) do |args|
        url = args[0] || ""
        URI.parse(url).scheme || ""
      end

      FunctionRegistry.register_function(:"url_host", 1) do |args|
        url = args[0] || ""
        URI.parse(url).host || ""
      end

      FunctionRegistry.register_function(:"url_port", 1) do |args|
        url = args[0] || ""
        port = URI.parse(url).port
        port ? port.to_s : ""
      end

      FunctionRegistry.register_function(:"url_path", 1) do |args|
        url = args[0] || ""
        URI.parse(url).path || ""
      end

      FunctionRegistry.register_function(:"url_query", 1) do |args|
        url = args[0] || ""
        URI.parse(url).query || ""
      end

      FunctionRegistry.register_function(:"url_fragment", 1) do |args|
        url = args[0] || ""
        URI.parse(url).fragment || ""
      end

      FunctionRegistry.register_function(:"is_absolute_url", 1) do |args|
        url = args[0] || ""
        URI.parse(url).absolute?.to_s
      end

      FunctionRegistry.register_function(:"is_valid_url", 1) do |args|
        url = args[0] || ""
        begin
          uri = URI.parse(url)
          (!uri.opaque? && !uri.scheme.nil?).to_s
        rescue
          "false"
        end
      end

      FunctionRegistry.register_function(:"url_join", 2) do |args|
        base = args[0]? || ""
        path = args[1]? || ""
        URI.parse(base).resolve(path).to_s
      end

      FunctionRegistry.register_function(:"url_components", 1) do |args|
        url = args[0] || ""
        uri = URI.parse(url)
        {
          scheme:   uri.scheme || "",
          host:     uri.host || "",
          port:     uri.port || "",
          path:     uri.path || "",
          query:    uri.query || "",
          fragment: uri.fragment || "",
          user:     uri.user || "",
          password: uri.password ? "***" : "",
        }.to_h.to_json
      end

      FunctionRegistry.register_function(:"query_params", 1) do |args|
        url = args[0] || ""
        uri = URI.parse(url)
        uri.query_params.to_h.to_json
      end

      FunctionRegistry.register_function(:"update_query_param", 3) do |args|
        url = args[0] || ""
        key = args[1]? || ""
        value = args[2]? || ""

        uri = URI.parse(url)
        uri.update_query_params do |params|
          params[key] = [value]
        end
        uri.to_s
      end
    end
  end
end
