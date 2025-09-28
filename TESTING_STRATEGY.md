# Lapis Testing Strategy & Plan

## Overview
This document outlines a comprehensive but sane testing strategy for Lapis using Crystal's built-in Spec framework. The goal is to provide stable, maintainable tests that help us move forward confidently without overkill.

## Testing Philosophy

### Core Principles
1. **Test Behavior, Not Implementation**: Focus on what the code does, not how it does it
2. **Test Critical Paths**: Prioritize tests that catch real bugs users would encounter
3. **Test Edge Cases**: Cover error conditions and boundary cases
4. **Keep Tests Fast**: Avoid slow tests that discourage running them frequently
5. **Test Integration Points**: Ensure components work together correctly

### Test Categories
- **Unit Tests**: Individual classes and methods
- **Integration Tests**: Component interactions
- **Functional Tests**: End-to-end workflows
- **Performance Tests**: Benchmarking and memory usage
- **Error Handling Tests**: Exception scenarios

## Test Structure

### Directory Organization
```
spec/
├── spec_helper.cr                 # Common setup and helpers
├── fixtures/                     # Test data and files
│   ├── content/                  # Sample content files
│   ├── configs/                  # Test configurations
│   └── templates/                # Test templates
├── unit/                         # Unit tests
│   ├── config_spec.cr
│   ├── content_spec.cr
│   ├── logger_spec.cr
│   ├── memory_manager_spec.cr
│   ├── performance_benchmark_spec.cr
│   ├── process_manager_spec.cr
│   ├── data_processor_spec.cr
│   ├── exceptions_spec.cr
│   └── functions_spec.cr
├── integration/                  # Integration tests
│   ├── generator_spec.cr
│   ├── server_spec.cr
│   ├── template_engine_spec.cr
│   └── plugin_system_spec.cr
├── functional/                   # End-to-end tests
│   ├── build_workflow_spec.cr
│   ├── serve_workflow_spec.cr
│   └── cli_spec.cr
└── performance/                  # Performance tests
    ├── memory_usage_spec.cr
    └── build_performance_spec.cr
```

## Test Implementation Plan

### Phase 1: Core Infrastructure (Priority: High)
1. **Logger Tests** - Ensure logging works correctly
2. **Exception Tests** - Verify error handling
3. **Memory Manager Tests** - Test GC control and monitoring
4. **Data Processor Tests** - JSON/YAML parsing and validation

### Phase 2: Core Business Logic (Priority: High)
1. **Config Tests** - Configuration loading and validation
2. **Content Tests** - Content parsing and processing
3. **Functions Tests** - Template function system
4. **Performance Benchmark Tests** - Benchmarking functionality

### Phase 3: Integration & Workflows (Priority: Medium)
1. **Generator Tests** - Build process integration
2. **Server Tests** - HTTP server functionality
3. **Template Engine Tests** - Template rendering
4. **CLI Tests** - Command-line interface

### Phase 4: Advanced Features (Priority: Low)
1. **Plugin System Tests** - Plugin loading and execution
2. **Process Manager Tests** - External process handling
3. **Performance Tests** - Memory and speed benchmarks

## Test Implementation Guidelines

### Using Crystal's Spec Framework
Based on the [Crystal Spec documentation](https://crystal-lang.org/api/1.17.1/Spec.html), we'll use:

```crystal
require "spec"

describe "ClassName" do
  describe "#method_name" do
    it "describes what it should do" do
      # Arrange
      setup_test_data
      
      # Act
      result = method_under_test
      
      # Assert
      result.should eq(expected_value)
    end
  end
  
  context "when in specific condition" do
    it "behaves differently" do
      # Test specific scenario
    end
  end
end
```

### Test Helpers and Fixtures
- **spec_helper.cr**: Common setup, shared helpers
- **fixtures/**: Reusable test data
- **before_each/after_each**: Setup and cleanup
- **Custom matchers**: Domain-specific assertions

### Test Tags
Use tags to organize and filter tests:
- `@[Tags("fast")]` - Quick unit tests
- `@[Tags("slow")]` - Integration/performance tests
- `@[Tags("integration")]` - Integration tests
- `@[Tags("performance")]` - Performance tests

### Mocking Strategy
- Use dependency injection for testable components
- Mock external dependencies (file system, network)
- Use test doubles for complex objects

## Specific Test Cases

### Logger Tests
```crystal
describe Lapis::Logger do
  describe ".setup" do
    it "initializes logging system" do
      Lapis::Logger.setup
      # Verify logging is configured
    end
  end
  
  describe ".info" do
    it "logs info messages with context" do
      Lapis::Logger.info("test message", key: "value")
      # Verify message is logged
    end
  end
end
```

### Memory Manager Tests
```crystal
describe Lapis::MemoryManager do
  describe "#current_memory_usage" do
    it "returns current memory usage" do
      manager = Lapis::MemoryManager.new
      usage = manager.current_memory_usage
      usage.should be_a(Int64)
      usage.should be >= 0
    end
  end
  
  describe "#with_gc_disabled" do
    it "disables GC during block execution" do
      manager = Lapis::MemoryManager.new
      manager.with_gc_disabled do
        # Verify GC is disabled
      end
      # Verify GC is re-enabled
    end
  end
end
```

### Content Tests
```crystal
describe Lapis::Content do
  describe ".load" do
    it "loads content from file" do
      content = Lapis::Content.load("spec/fixtures/content/sample.md")
      content.title.should eq("Sample Post")
      content.content.should contain("markdown content")
    end
    
    it "handles missing files gracefully" do
      expect_raises(Lapis::ContentError) do
        Lapis::Content.load("nonexistent.md")
      end
    end
  end
  
  describe "#url" do
    it "generates correct URL for posts" do
      content = create_test_content("posts/sample.md")
      content.url.should eq("/2024/01/15/sample/")
    end
  end
end
```

### Generator Tests
```crystal
describe Lapis::Generator do
  describe "#build" do
    it "builds site successfully" do
      config = create_test_config
      generator = Lapis::Generator.new(config)
      
      generator.build
      
      # Verify output files exist
      File.exists?("test_output/index.html").should be_true
    end
    
    it "handles build errors gracefully" do
      config = create_invalid_config
      generator = Lapis::Generator.new(config)
      
      expect_raises(Lapis::BuildError) do
        generator.build
      end
    end
  end
end
```

## Test Execution Strategy

### Running Tests
```bash
# Run all tests
crystal spec

# Run specific test file
crystal spec spec/unit/content_spec.cr

# Run tests with specific tag
crystal spec --tag 'fast'

# Run tests excluding slow tests
crystal spec --tag '~slow'

# Run tests in random order
crystal spec --order random
```

### CI/CD Integration
- Run fast tests on every commit
- Run full test suite on pull requests
- Run performance tests nightly
- Generate test coverage reports

## Test Data Management

### Fixtures
- **Content files**: Sample markdown with frontmatter
- **Config files**: Various configuration scenarios
- **Templates**: Test template files
- **Assets**: Sample images, CSS, JS files

### Test Isolation
- Each test should be independent
- Use temporary directories for output
- Clean up after each test
- Avoid shared state between tests

## Performance Considerations

### Test Speed
- Unit tests should run in < 1ms each
- Integration tests should run in < 100ms each
- Performance tests can be slower but should be tagged

### Memory Usage
- Tests should not leak memory
- Use memory manager to monitor test memory usage
- Clean up large objects after tests

## Maintenance Strategy

### Test Maintenance
- Review tests when changing implementation
- Update tests when requirements change
- Remove obsolete tests
- Refactor tests for better readability

### Test Documentation
- Document complex test scenarios
- Explain why certain tests exist
- Keep test names descriptive
- Use comments for complex setup

## Success Metrics

### Coverage Goals
- **Unit Tests**: 80%+ line coverage
- **Integration Tests**: 60%+ integration coverage
- **Critical Paths**: 100% coverage

### Quality Metrics
- Tests catch real bugs before production
- Tests run fast enough for frequent execution
- Tests are maintainable and readable
- Tests provide confidence in refactoring

## Implementation Timeline

### Week 1: Infrastructure
- Set up test structure
- Implement spec_helper.cr
- Create basic fixtures
- Implement Logger and Exception tests

### Week 2: Core Logic
- Implement Config and Content tests
- Add Memory Manager tests
- Create Data Processor tests
- Add Functions tests

### Week 3: Integration
- Implement Generator tests
- Add Server tests
- Create Template Engine tests
- Add CLI tests

### Week 4: Advanced Features
- Implement Plugin System tests
- Add Process Manager tests
- Create Performance tests
- Add end-to-end workflow tests

This testing strategy provides a solid foundation for maintaining code quality while avoiding overkill. The focus is on testing behavior that matters to users and catching bugs that would impact the development experience.
