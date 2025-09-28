require "../spec_helper"

describe Lapis::DataProcessor do
  describe ".parse_json" do
    it "parses valid JSON", tags: [TestTags::FAST, TestTags::UNIT] do
      json_content = "{\"title\": \"Test\", \"count\": 42, \"active\": true}"
      result = Lapis::DataProcessor.parse_json(json_content)

      result.should be_a(JSON::Any)
      result["title"].as_s.should eq("Test")
      result["count"].as_i.should eq(42)
      result["active"].as_bool.should be_true
    end

    it "handles invalid JSON gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_json = "{\"title\": \"Test\", \"count\": 42, \"active\": true"

      expect_raises(Lapis::ValidationError) do
        Lapis::DataProcessor.parse_json(invalid_json)
      end
    end
  end

  describe ".parse_yaml" do
    it "parses valid YAML", tags: [TestTags::FAST, TestTags::UNIT] do
      yaml_content = <<-YAML
      title: Test
      count: 42
      active: true
      tags: [test, yaml]
      YAML

      result = Lapis::DataProcessor.parse_yaml(yaml_content)

      result.should be_a(YAML::Any)
      result["title"].as_s.should eq("Test")
      result["count"].as_i.should eq(42)
      result["active"].as_bool.should be_true
    end

    it "handles invalid YAML gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_yaml = <<-YAML
      title: Test
      invalid: yaml: content: here
      YAML

      expect_raises(Lapis::ValidationError) do
        Lapis::DataProcessor.parse_yaml(invalid_yaml)
      end
    end
  end

  describe ".json_to_yaml" do
    it "converts JSON to YAML", tags: [TestTags::FAST, TestTags::UNIT] do
      json_content = "{\"title\": \"Test\", \"count\": 42}"
      json_data = Lapis::DataProcessor.parse_json(json_content)
      yaml_result = Lapis::DataProcessor.json_to_yaml(json_data)

      yaml_result.should contain("title: Test")
      yaml_result.should contain("count: 42")
    end

    it "handles invalid JSON during conversion", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_json = "{\"title\": \"Test\", \"count\": 42"

      expect_raises(Lapis::ValidationError) do
        json_data = Lapis::DataProcessor.parse_json(invalid_json)
        Lapis::DataProcessor.json_to_yaml(json_data)
      end
    end
  end

  describe ".yaml_to_json" do
    it "converts YAML to JSON", tags: [TestTags::FAST, TestTags::UNIT] do
      yaml_content = <<-YAML
      title: Test
      count: 42
      YAML

      yaml_data = Lapis::DataProcessor.parse_yaml(yaml_content)
      json_result = Lapis::DataProcessor.yaml_to_json(yaml_data)

      json_result.should contain("\"title\":\"Test\"")
      json_result.should contain("\"count\":42")
    end

    it "handles invalid YAML during conversion", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_yaml = <<-YAML
      title: Test
      invalid: yaml: content: here
      YAML

      expect_raises(Lapis::ValidationError) do
        yaml_data = Lapis::DataProcessor.parse_yaml(invalid_yaml)
        Lapis::DataProcessor.yaml_to_json(yaml_data)
      end
    end
  end

  describe ".pretty_print_json" do
    it "pretty prints JSON", tags: [TestTags::FAST, TestTags::UNIT] do
      json_content = "{\"title\":\"Test\",\"count\":42,\"active\":true}"
      json_data = Lapis::DataProcessor.parse_json(json_content)
      pretty_result = Lapis::DataProcessor.pretty_json(json_data)

      pretty_result.should contain("\"title\": \"Test\"")
      pretty_result.should contain("\"count\": 42")
      pretty_result.should contain("\"active\": true")
    end

    it "handles invalid JSON during pretty print", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_json = "{\"title\": \"Test\", \"count\": 42"

      expect_raises(Lapis::ValidationError) do
        json_data = Lapis::DataProcessor.parse_json(invalid_json)
        Lapis::DataProcessor.pretty_json(json_data)
      end
    end
  end

  describe ".extract_fields" do
    it "extracts specific fields from JSON data", tags: [TestTags::FAST, TestTags::UNIT] do
      json_content = "{\"title\": \"Test\", \"count\": 42, \"active\": true}"
      json_data = Lapis::DataProcessor.parse_json(json_content)

      fields = Lapis::DataProcessor.extract_fields(json_data, ["title", "count"])

      fields.should be_a(Hash(String, JSON::Any | YAML::Any))
      fields["title"].as_s.should eq("Test")
      fields["count"].as_i.should eq(42)
      fields.keys.should_not contain("active")
    end

    it "handles non-existent fields gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      json_content = "{\"title\": \"Test\"}"
      json_data = Lapis::DataProcessor.parse_json(json_content)

      fields = Lapis::DataProcessor.extract_fields(json_data, ["title", "nonexistent"])

      fields.keys.should contain("title")
      fields.keys.should_not contain("nonexistent")
    end
  end

  describe ".parse_yaml_safe" do
    it "returns default value when parsing fails", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_yaml = "invalid: yaml: content"
      default_value = YAML::Any.new("default")

      result = Lapis::DataProcessor.parse_yaml_safe(invalid_yaml, default_value)

      result.should eq(default_value)
    end

    it "uses nil as default when no default provided", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_yaml = "invalid: yaml: content"

      result = Lapis::DataProcessor.parse_yaml_safe(invalid_yaml)

      result.should be_nil
    end
  end

  describe ".parse_json_typed" do
    it "parses JSON with type safety", tags: [TestTags::FAST, TestTags::UNIT] do
      json_content = "{\"title\": \"Test\", \"count\": 42, \"active\": true, \"tags\": [\"test\", \"json\"]}"
      result = Lapis::DataProcessor.parse_json_typed(json_content)

      result.should be_a(Lapis::DataProcessor::PostData)
      result.title.should eq("Test")
      result.count.should eq(42)
      result.active.should be_true
      result.tags.should eq(["test", "json"])
    end

    it "handles missing optional fields", tags: [TestTags::FAST, TestTags::UNIT] do
      json_content = "{\"title\": \"Test\", \"count\": 42, \"active\": true}"
      result = Lapis::DataProcessor.parse_json_typed(json_content)

      result.should be_a(Lapis::DataProcessor::PostData)
      result.title.should eq("Test")
      result.count.should eq(42)
      result.active.should be_true
      result.tags.should be_nil
    end

    it "handles invalid JSON gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      invalid_json = "{\"title\": \"Test\", \"count\": 42, \"active\": true"

      expect_raises(Lapis::ValidationError) do
        Lapis::DataProcessor.parse_json_typed(invalid_json)
      end
    end

    it "handles TypeCastError in JSON parsing", tags: [TestTags::FAST, TestTags::UNIT] do
      # This test verifies that TypeCastError is properly handled
      # The actual TypeCastError would be triggered by JSON deserialization issues
      invalid_json = "{\"title\": \"Test\", \"count\": \"not_a_number\", \"active\": true}"

      expect_raises(Lapis::ValidationError) do
        Lapis::DataProcessor.parse_json_typed(invalid_json)
      end
    end
  end

  describe ".merge_data" do
    it "returns nil when no data objects provided", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::DataProcessor.merge_data([] of JSON::Any | YAML::Any)

      result.should be_nil
    end

    it "merges multiple JSON objects", tags: [TestTags::FAST, TestTags::UNIT] do
      json1 = Lapis::DataProcessor.parse_json("{\"title\": \"Test\", \"count\": 42}")
      json2 = Lapis::DataProcessor.parse_json("{\"active\": true, \"tags\": [\"test\"]}")

      result = Lapis::DataProcessor.merge_data([json1, json2])

      result.should_not be_nil
      result.not_nil!["title"].as_s.should eq("Test")
      result.not_nil!["count"].as_i.should eq(42)
      result.not_nil!["active"].as_bool.should be_true
      result.not_nil!["tags"].as_a.size.should eq(1)
    end
  end
end
