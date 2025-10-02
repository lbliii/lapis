# Makefile for Lapis

.PHONY: help install test lint lint-fix build clean setup-hooks

# Default target
help:
	@echo "Available targets:"
	@echo "  install      - Install dependencies"
	@echo "  test         - Run tests"
	@echo "  lint         - Run Ameba linter"
	@echo "  lint-fix     - Run Ameba linter with auto-fix"
	@echo "  build        - Build the project"
	@echo "  clean        - Clean build artifacts"
	@echo "  setup-hooks  - Install git pre-commit hooks"

# Install dependencies
install:
	shards install

# Run tests with enhanced output (excludes performance tests by default)
test:
	./scripts/test.sh

# Run linter
lint:
	./bin/ameba

# Run linter with auto-fix
lint-fix:
	./bin/ameba --fix

# Build the project
build:
	crystal build src/lapis.cr --release

# Clean build artifacts
clean:
	rm -f lapis
	rm -rf .crystal/

# Setup git hooks
setup-hooks:
	./scripts/setup-hooks.sh

# CI target (used by GitHub Actions)
ci: install lint test build
