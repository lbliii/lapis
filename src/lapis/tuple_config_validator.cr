require "./logger"
require "./exceptions"

module Lapis
  # Enhanced tuple-based configuration validation system with NamedTuple features
  class TupleConfigValidator
    # Pre-computed validation tuples for performance
    private REQUIRED_CONFIG_KEYS = {
      :title, :base_url, :theme, :output_dir, :content_dir,
    }

    private OPTIONAL_CONFIG_KEYS = {
      :description, :author, :copyright, :build_config, :live_reload_config,
      :bundling_config, :debug, :layouts_dir, :static_dir, :theme_dir,
    }

    private VALID_THEMES = {
      :default, :minimal, :blog, :documentation, :portfolio,
    }

    private VALID_BUILD_MODES = {
      :development, :production, :test,
    }

    # NamedTuple type definitions for type-safe configuration handling
    alias ConfigStructure = NamedTuple(
      title: String,
      base_url: String,
      theme: String,
      output_dir: String,
      content_dir: String,
      description: String?,
      author: String?,
      copyright: String?,
      debug: Bool?)

    alias BuildConfigStructure = NamedTuple(
      build_options: Int32?,
      cache_dir: String?,
      max_workers: Int32?)

    alias LiveReloadConfigStructure = NamedTuple(
      enabled: Bool?,
      websocket_path: String?,
      debounce_ms: Int32?,
      watch_options: Int32?)

    def initialize
    end

    # Tuple-based configuration validation using tuple operations
    def validate_config(config : Hash(String, YAML::Any)) : Tuple(Bool, Array(String))
      raise ArgumentError.new("Config cannot be nil") if config.nil?

      errors = [] of String

      # Use tuple operations for efficient validation
      required_errors = validate_required_keys_tuple(config)
      optional_errors = validate_optional_keys_tuple(config)
      value_errors = validate_config_values_tuple(config)

      # Combine errors using tuple operations
      all_errors = required_errors + optional_errors + value_errors

      {all_errors.empty?, all_errors}
    end

    # Tuple-based required key validation
    private def validate_required_keys_tuple(config : Hash(String, YAML::Any)) : Array(String)
      errors = [] of String

      # Use tuple operations for efficient iteration
      REQUIRED_CONFIG_KEYS.to_a.each do |key|
        key_str = key.to_s
        if !config.has_key?(key_str) || config[key_str].to_s.strip.empty?
          errors << "Required configuration key '#{key_str}' is missing or empty"
        end
      end

      errors
    end

    # Tuple-based optional key validation
    private def validate_optional_keys_tuple(config : Hash(String, YAML::Any)) : Array(String)
      errors = [] of String

      # Use tuple operations for type validation
      OPTIONAL_CONFIG_KEYS.to_a.each do |key|
        key_str = key.to_s
        next unless config.has_key?(key_str)

        # Validate specific optional keys using tuple operations
        case key
        when :build_config
          errors.concat(validate_build_config_tuple(config[key_str]))
        when :live_reload_config
          errors.concat(validate_live_reload_config_tuple(config[key_str]))
        when :bundling_config
          errors.concat(validate_bundling_config_tuple(config[key_str]))
        end
      end

      errors
    end

    # Tuple-based value validation
    private def validate_config_values_tuple(config : Hash(String, YAML::Any)) : Array(String)
      errors = [] of String

      # Use tuple operations for efficient value validation
      value_validation_tuples = {
        {:theme, config["theme"]?, VALID_THEMES, "theme"},
        {:build_mode, config["build_config"]?.try(&.["mode"]?), VALID_BUILD_MODES, "build mode"},
      }

      value_validation_tuples.each do |validation_tuple|
        key, value, valid_values, description = validation_tuple

        if value && !valid_values.to_a.map(&.to_s).includes?(value.to_s)
          raise ArgumentError.new("Invalid #{description}: '#{value}' (valid options: #{valid_values.to_a.join(", ")})")
        end
      end

      errors
    end

    # Tuple-based build config validation
    private def validate_build_config_tuple(build_config : YAML::Any) : Array(String)
      errors = [] of String

      return errors unless build_config.as_h?

      config_hash = build_config.as_h

      # Use tuple operations for build config validation
      build_config_keys = {:build_options, :cache_dir, :max_workers}

      build_config_keys.to_a.each do |key|
        key_str = key.to_s
        next unless config_hash.has_key?(key_str)

        case key
        when :build_options
          # Validate build options flags
          options_value = config_hash[key_str]
          if options_value.as_i?
            # Check if it's a valid combination of flags
            flags = options_value.as_i
            valid_flags = BuildOptions::Incremental.value | BuildOptions::Parallel.value | BuildOptions::CleanBuild.value
            unless (flags & ~valid_flags) == 0
              raise ArgumentError.new("Build config '#{key_str}' contains invalid flag combinations")
            end
          elsif options_value.as_s?
            # Handle string representation like "Incremental | Parallel"
            begin
              BuildOptions.parse(options_value.as_s)
            rescue
              errors << "Build config '#{key_str}' must be a valid flag combination"
            end
          else
            errors << "Build config '#{key_str}' must be a valid flag value"
          end
        when :max_workers
          unless config_hash[key_str].as_i? && config_hash[key_str].as_i > 0
            errors << "Build config '#{key_str}' must be a positive integer"
          end
        when :cache_dir
          if !config_hash[key_str].as_s? || config_hash[key_str].as_s.strip.empty?
            errors << "Build config '#{key_str}' must be a non-empty string"
          end
        end
      end

      errors
    end

    # Tuple-based live reload config validation
    private def validate_live_reload_config_tuple(live_reload_config : YAML::Any) : Array(String)
      errors = [] of String

      return errors unless live_reload_config.as_h?

      config_hash = live_reload_config.as_h

      # Use tuple operations for live reload config validation
      live_reload_keys = {:enabled, :websocket_path, :debounce_ms, :watch_options}

      live_reload_keys.to_a.each do |key|
        key_str = key.to_s
        next unless config_hash.has_key?(key_str)

        case key
        when :enabled
          unless config_hash[key_str].as_bool?
            errors << "Live reload config '#{key_str}' must be a boolean"
          end
        when :websocket_path
          unless config_hash[key_str].as_s? && config_hash[key_str].as_s.starts_with?("/")
            errors << "Live reload config '#{key_str}' must be a valid path starting with '/'"
          end
        when :debounce_ms
          unless config_hash[key_str].as_i? && config_hash[key_str].as_i > 0
            errors << "Live reload config '#{key_str}' must be a positive integer"
          end
        when :watch_options
          # Validate watch options flags
          options_value = config_hash[key_str]
          if options_value.as_i?
            # Check if it's a valid combination of flags
            flags = options_value.as_i
            valid_flags = WatchOptions::Content.value | WatchOptions::Layouts.value | WatchOptions::Static.value | WatchOptions::Config.value
            unless (flags & ~valid_flags) == 0
              errors << "Live reload config '#{key_str}' contains invalid flag combinations"
            end
          elsif options_value.as_s?
            # Handle string representation like "Content | Layouts"
            begin
              WatchOptions.parse(options_value.as_s)
            rescue
              errors << "Live reload config '#{key_str}' must be a valid flag combination"
            end
          else
            errors << "Live reload config '#{key_str}' must be a valid flag value"
          end
        end
      end

      errors
    end

    # Tuple-based bundling config validation
    private def validate_bundling_config_tuple(bundling_config : YAML::Any) : Array(String)
      errors = [] of String

      return errors unless bundling_config.as_h?

      config_hash = bundling_config.as_h

      # Use tuple operations for bundling config validation
      bundling_keys = {:bundling_options}

      bundling_keys.to_a.each do |key|
        key_str = key.to_s
        next unless config_hash.has_key?(key_str)

        case key
        when :bundling_options
          # Validate bundling options flags
          options_value = config_hash[key_str]
          if options_value.as_i?
            # Check if it's a valid combination of flags
            flags = options_value.as_i
            valid_flags = BundlingOptions::Enabled.value | BundlingOptions::Minify.value | BundlingOptions::SourceMaps.value | BundlingOptions::Autoprefix.value | BundlingOptions::TreeShake.value
            unless (flags & ~valid_flags) == 0
              errors << "Bundling config '#{key_str}' contains invalid flag combinations"
            end
          elsif options_value.as_s?
            # Handle string representation like "Enabled | Minify"
            begin
              BundlingOptions.parse(options_value.as_s)
            rescue
              errors << "Bundling config '#{key_str}' must be a valid flag combination"
            end
          else
            errors << "Bundling config '#{key_str}' must be a valid flag value"
          end
        end
      end

      errors
    end

    # Tuple-based configuration normalization
    def normalize_config(config : Hash(String, YAML::Any)) : Hash(String, YAML::Any)
      normalized = config.dup

      # Use tuple operations for efficient normalization
      normalization_tuples = {
        {:base_url, ->(v : YAML::Any) { YAML::Any.new(v.to_s.chomp('/')) }},
        {:content_dir, ->(v : YAML::Any) { YAML::Any.new(v.to_s.chomp('/')) }},
        {:output_dir, ->(v : YAML::Any) { YAML::Any.new(v.to_s.chomp('/')) }},
        {:layouts_dir, ->(v : YAML::Any) { YAML::Any.new(v.to_s.chomp('/')) }},
        {:static_dir, ->(v : YAML::Any) { YAML::Any.new(v.to_s.chomp('/')) }},
        {:theme_dir, ->(v : YAML::Any) { YAML::Any.new(v.to_s.chomp('/')) }},
      }

      normalization_tuples.each do |normalization_tuple|
        key, normalizer = normalization_tuple
        key_str = key.to_s

        if normalized.has_key?(key_str)
          normalized[key_str] = normalizer.call(normalized[key_str])
        end
      end

      normalized
    end

    # Enhanced NamedTuple-based configuration merging
    def merge_configs(base_config : Hash(String, YAML::Any), override_config : Hash(String, YAML::Any)) : Hash(String, YAML::Any)
      # Start with base config
      merged = base_config.dup

      # Override with values from override_config
      override_config.each do |key, value|
        merged[key] = value
      end

      merged
    end

    # NamedTuple-based safe nested access using dig?
    def safe_config_access(config : Hash(String, YAML::Any), *keys) : YAML::Any?
      config_tuple = convert_hash_to_config_tuple(config)
      config_tuple.dig?(*keys)
    end

    # Convert Hash to type-safe ConfigStructure NamedTuple
    private def convert_hash_to_config_tuple(config : Hash(String, YAML::Any)) : ConfigStructure
      ConfigStructure.from({
        "title"       => config["title"]?.try(&.as_s) || "Default Site",
        "base_url"    => config["base_url"]?.try(&.as_s) || "",
        "theme"       => config["theme"]?.try(&.as_s) || "default",
        "output_dir"  => config["output_dir"]?.try(&.as_s) || "public",
        "content_dir" => config["content_dir"]?.try(&.as_s) || "content",
        "description" => config["description"]?.try(&.as_s),
        "author"      => config["author"]?.try(&.as_s),
        "copyright"   => config["copyright"]?.try(&.as_s),
        "debug"       => config["debug"]?.try(&.as_bool),
      })
    end

    # Convert ConfigStructure NamedTuple back to Hash
    private def convert_config_tuple_to_hash(config_tuple : ConfigStructure) : Hash(String, YAML::Any)
      config_tuple.to_h.transform_keys(&.to_s).transform_values { |v| YAML::Any.new(v) }
    end

    # Enhanced configuration merging with type safety
    def merge_configs_typed(base_config : ConfigStructure, override_config : ConfigStructure) : ConfigStructure
      base_config.merge(override_config)
    end

    # Tuple-based configuration comparison
    def config_diff(config1 : Hash(String, YAML::Any), config2 : Hash(String, YAML::Any)) : NamedTuple(added: Array(String), removed: Array(String), changed: Array(String))
      keys1 = config1.keys.to_set
      keys2 = config2.keys.to_set

      # Use tuple operations for efficient comparison
      added = (keys2 - keys1).to_a
      removed = (keys1 - keys2).to_a
      changed = [] of String

      # Use tuple operations for changed value detection
      common_keys = (keys1 & keys2).to_a
      common_keys.each do |key|
        if config1[key] != config2[key]
          changed << key
        end
      end

      {added: added, removed: removed, changed: changed}
    end
  end
end
