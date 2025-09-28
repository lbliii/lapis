#!/bin/bash
set -e

# Lapis Release Management Script
# Usage: ./scripts/release.sh [version] [--dry-run]
# Example: ./scripts/release.sh 0.3.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
VERSION="$1"
DRY_RUN="$2"

if [[ -z "$VERSION" ]]; then
    log_error "Version is required"
    echo "Usage: $0 <version> [--dry-run]"
    echo "Example: $0 0.3.0"
    exit 1
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Version must be in format X.Y.Z (e.g., 0.3.0)"
    exit 1
fi

TAG="v$VERSION"

log_info "🚀 Starting release process for version $VERSION"

cd "$ROOT_DIR"

# Pre-flight checks
log_info "Running pre-flight checks..."

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    log_error "Must be on main branch to create a release (currently on: $CURRENT_BRANCH)"
    exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    log_error "Uncommitted changes detected. Please commit or stash changes before releasing."
    git status --short
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    log_error "Tag $TAG already exists"
    exit 1
fi

# Pull latest changes
log_info "Pulling latest changes from origin..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    git pull origin main
fi

# Update version in shard.yml
log_info "Updating version in shard.yml..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    sed -i.bak "s/^version: .*/version: $VERSION/" shard.yml
    rm shard.yml.bak
    log_success "Updated shard.yml to version $VERSION"
else
    log_info "Would update shard.yml to version $VERSION"
fi

# Run tests and quality checks
log_info "Running tests and quality checks..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    crystal tool format --check
    shards install
    shards run ameba
    crystal spec
    log_success "All tests and checks passed"
else
    log_info "Would run: crystal tool format --check, ameba, and crystal spec"
fi

# Build release binary
log_info "Building release binary..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    crystal build src/lapis.cr --release -o bin/lapis
    log_success "Built release binary"
else
    log_info "Would build release binary"
fi

# Test example site build
log_info "Testing example site build..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    cd exampleSite
    ../bin/lapis build
    cd ..
    log_success "Example site builds successfully"
else
    log_info "Would test example site build"
fi

# Update CHANGELOG.md with release date
log_info "Updating CHANGELOG.md with release date..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    TODAY=$(date +%Y-%m-%d)
    sed -i.bak "s/## \[$VERSION\] - .*/## [$VERSION] - $TODAY/" CHANGELOG.md
    rm CHANGELOG.md.bak
    log_success "Updated CHANGELOG.md with release date"
else
    log_info "Would update CHANGELOG.md with today's date"
fi

# Commit version changes
log_info "Committing version changes..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    git add shard.yml CHANGELOG.md
    git commit -m "chore: bump version to $VERSION

🚀 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    log_success "Committed version changes"
else
    log_info "Would commit version changes"
fi

# Create and push tag
log_info "Creating and pushing tag $TAG..."
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    git tag -a "$TAG" -m "Release $VERSION

$(head -50 CHANGELOG.md | grep -A 30 "## \[$VERSION\]" | tail -n +2 | head -n 20)

🚀 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    git push origin main
    git push origin "$TAG"
    log_success "Created and pushed tag $TAG"
else
    log_info "Would create and push tag $TAG"
fi

# Summary
echo ""
log_success "🎉 Release $VERSION ready!"
echo ""
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    log_info "Next steps:"
    echo "  1. GitHub Actions will automatically create the release"
    echo "  2. Monitor the build at: https://github.com/lapis-lang/lapis/actions"
    echo "  3. Release will be available at: https://github.com/lapis-lang/lapis/releases/tag/$TAG"
else
    log_info "This was a dry run. To actually create the release, run:"
    echo "  ./scripts/release.sh $VERSION"
fi

echo ""
log_info "Release artifacts that will be created:"
echo "  • GitHub release with release notes"
echo "  • Linux x86_64 binary (lapis-linux-x86_64)"
echo "  • Automatic changelog integration"
echo ""