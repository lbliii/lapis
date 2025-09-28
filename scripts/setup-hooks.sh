#!/bin/bash

# Setup script for git hooks
# This script sets up pre-commit hooks for the Lapis project

set -e

echo "🔧 Setting up git hooks for Lapis..."

# Get the project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Not in a git repository. Please run this from the project root."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/.git/hooks"

# Copy pre-commit hook
cp "$PROJECT_ROOT/.githooks/pre-commit" "$PROJECT_ROOT/.git/hooks/pre-commit"
chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "📋 The hook will now run Ameba on staged Crystal files before each commit."
echo "💡 To bypass the hook (not recommended), use: git commit --no-verify"
echo ""
echo "🧪 Test the hook by staging some files and running: git commit -m 'test'"
