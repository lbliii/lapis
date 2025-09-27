# Contributing to Lapis

Thank you for your interest in contributing to Lapis! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- Crystal 1.0 or later
- Git
- Basic knowledge of Crystal syntax

### Setting Up Development Environment

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/lapis.git
   cd lapis
   ```
3. Install dependencies:
   ```bash
   shards install
   ```
4. Build the project:
   ```bash
   crystal build src/lapis.cr
   ```
5. Run tests to ensure everything works:
   ```bash
   crystal spec
   ```

## 📝 Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/amazing-new-feature
```

### 2. Make Your Changes

- Write clean, readable code
- Follow Crystal conventions
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all tests
crystal spec

# Run linter
shards run ameba

# Test the CLI manually
crystal run src/lapis.cr -- init test-site
cd test-site
crystal run ../src/lapis.cr -- serve
```

### 4. Commit Your Changes

Use clear, descriptive commit messages:

```bash
git add .
git commit -m "Add support for custom permalinks

- Implement permalink configuration in config.yml
- Add URL generation logic in Content class
- Update documentation with examples"
```

### 5. Submit a Pull Request

1. Push your branch to your fork:
   ```bash
   git push origin feature/amazing-new-feature
   ```
2. Create a pull request on GitHub
3. Describe your changes clearly
4. Link any relevant issues

## 🏗️ Code Guidelines

### Crystal Style

- Follow the [Crystal style guide](https://crystal-lang.org/reference/conventions/coding_style.html)
- Use meaningful variable and method names
- Keep methods focused and small
- Add type annotations where helpful

### Documentation

- Document public methods and classes
- Update README.md for user-facing changes
- Add examples for new features
- Keep documentation clear and concise

### Testing

- Write tests for new functionality
- Test both happy path and edge cases
- Use descriptive test names
- Mock external dependencies when needed

Example test:

```crystal
describe Lapis::Content do
  it "generates SEO-friendly URLs from titles" do
    content = create_test_content(title: "My Amazing Post!")
    content.url.should eq("/my-amazing-post/")
  end

  it "handles special characters in URLs" do
    content = create_test_content(title: "C++ vs Crystal")
    content.url.should eq("/c-vs-crystal/")
  end
end
```

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Clear description** of the issue
2. **Steps to reproduce** the problem
3. **Expected behavior** vs actual behavior
4. **Environment details**:
   - Crystal version
   - Operating system
   - Lapis version
5. **Sample code or configuration** if applicable
6. **Error messages** or logs

Use this template:

```markdown
## Bug Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Crystal version: 1.0.0
- OS: macOS 12.0
- Lapis version: 0.1.0

## Additional Context
Any other relevant information
```

## ✨ Feature Requests

For feature requests, please:

1. **Check existing issues** to avoid duplicates
2. **Describe the use case** clearly
3. **Explain the expected behavior**
4. **Consider the scope** - is this a core feature or plugin?
5. **Provide examples** if possible

## 📁 Project Structure

Understanding the codebase:

```
src/
├── lapis.cr           # Main entry point
└── lapis/
    ├── cli.cr         # Command-line interface
    ├── config.cr      # Configuration management
    ├── content.cr     # Content processing
    ├── generator.cr   # Static site generation
    ├── server.cr      # Development server
    └── templates.cr   # Template engine

spec/                  # Test files
themes/               # Default themes
examples/             # Example sites
```

## 🎯 Good First Issues

Looking for a place to start? Check out issues labeled:

- `good first issue` - Beginner-friendly tasks
- `help wanted` - Tasks that need contributors
- `documentation` - Documentation improvements

Some ideas for first contributions:

- Fix typos in documentation
- Add more test cases
- Improve error messages
- Add new template functions
- Create example sites

## 🔄 Release Process

For maintainers:

1. Update version in `shard.yml` and `src/lapis.cr`
2. Update `CHANGELOG.md`
3. Create release tag: `git tag v0.1.0`
4. Push tag: `git push origin v0.1.0`
5. Create GitHub release with release notes

## 💬 Community

- **GitHub Discussions**: For questions and general discussion
- **GitHub Issues**: For bugs and feature requests
- **Pull Requests**: For code contributions

## 📄 License

By contributing to Lapis, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be recognized in:

- GitHub contributors list
- Release notes
- Project documentation

Thank you for making Lapis better! 🎉