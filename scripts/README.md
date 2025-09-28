# Scripts Directory

This directory contains automation scripts for Lapis development and release management.

## Release Management

### `release.sh` - Automated Release Script

Streamlines the release process with automated checks, version updates, and tagging.

#### Usage

```bash
# Create a new release
./scripts/release.sh 0.3.0

# Dry run (preview what would happen)
./scripts/release.sh 0.3.0 --dry-run
```

#### What it does

1. **Pre-flight checks**:
   - Ensures you're on the `main` branch
   - Checks for uncommitted changes
   - Verifies tag doesn't already exist
   - Pulls latest changes

2. **Version management**:
   - Updates `shard.yml` with new version
   - Updates `CHANGELOG.md` with release date
   - Commits version changes

3. **Quality assurance**:
   - Runs code formatting checks (`crystal tool format --check`)
   - Runs linter (`shards run ameba`)
   - Runs test suite (`crystal spec`)
   - Builds release binary
   - Tests example site build

4. **Release creation**:
   - Creates annotated git tag with changelog excerpt
   - Pushes changes and tag to GitHub
   - Triggers GitHub Actions for automated release

#### Benefits

- **Consistency**: Same process every time
- **Safety**: Multiple checks prevent broken releases
- **Automation**: Reduces manual steps and errors
- **Documentation**: Clear audit trail of what was done

#### GitHub Integration

The script works seamlessly with the GitHub Actions workflow:

- When a `v*` tag is pushed, GitHub Actions automatically:
  - Runs the full test suite across multiple Crystal versions
  - Creates a GitHub release with changelog
  - Builds and uploads release binaries
  - Publishes release notes

#### Examples

```bash
# Release version 0.3.0
./scripts/release.sh 0.3.0

# Preview what would happen for 0.3.0
./scripts/release.sh 0.3.0 --dry-run

# Check script help
./scripts/release.sh
```

#### Manual Release Process (Fallback)

If you need to create a release manually:

1. Update version in `shard.yml`
2. Update release date in `CHANGELOG.md`
3. Run tests: `crystal spec`
4. Commit changes: `git commit -m "chore: bump version to X.Y.Z"`
5. Create tag: `git tag -a vX.Y.Z -m "Release X.Y.Z"`
6. Push: `git push origin main && git push origin vX.Y.Z`

The automation script does all of this plus additional safety checks.