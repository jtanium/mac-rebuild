#!/bin/bash

# Release automation script for mac-rebuild
# Handles versioning, tagging, and Homebrew formula updates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAIN_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMEBREW_REPO_DIR="../homebrew-mac-rebuild"
FORMULA_FILE="$HOMEBREW_REPO_DIR/Formula/mac-rebuild.rb"

# Utility functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Validate environment
validate_environment() {
    log "Validating environment..."

    # Check if we're in the right directory
    if [[ ! -f "mac-rebuild" ]] || [[ ! -d "lib/mac-rebuild" ]]; then
        error "Must be run from the mac-rebuild repository root"
    fi

    # Check if homebrew repo exists
    if [[ ! -d "$HOMEBREW_REPO_DIR" ]]; then
        error "Homebrew repository not found at $HOMEBREW_REPO_DIR"
    fi

    if [[ ! -f "$FORMULA_FILE" ]]; then
        error "Formula file not found at $FORMULA_FILE"
    fi

    # Check if git is available
    if ! command -v git &> /dev/null; then
        error "git is required but not installed"
    fi

    # Check if we're on main branch in both repos
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "main" ]]; then
        error "Must be on main branch in mac-rebuild repo (currently on: $current_branch)"
    fi

    cd "$HOMEBREW_REPO_DIR"
    local homebrew_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$homebrew_branch" != "main" ]]; then
        error "Must be on main branch in homebrew-mac-rebuild repo (currently on: $homebrew_branch)"
    fi
    cd "$MAIN_REPO_DIR"

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        error "Uncommitted changes in mac-rebuild repo. Please commit or stash them."
    fi

    cd "$HOMEBREW_REPO_DIR"
    if ! git diff --quiet || ! git diff --cached --quiet; then
        error "Uncommitted changes in homebrew-mac-rebuild repo. Please commit or stash them."
    fi
    cd "$MAIN_REPO_DIR"

    success "Environment validation passed"
}

# Get current version from git tags
get_current_version() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
}

# Increment version number
increment_version() {
    local version="$1"
    local type="$2"

    # Remove 'v' prefix if present
    version=${version#v}

    # Split version into parts
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]:-0}
    local minor=${VERSION_PARTS[1]:-0}
    local patch=${VERSION_PARTS[2]:-0}

    case "$type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            error "Invalid version type: $type"
            ;;
    esac

    echo "v$major.$minor.$patch"
}

# Update CHANGELOG.md
update_changelog() {
    local version="$1"
    local date=$(date '+%Y-%m-%d')

    log "Updating CHANGELOG.md..."

    # Create a temporary file with the new entry
    cat > /tmp/changelog_entry << EOF
## [$version] - $date

### Added
-

### Changed
-

### Fixed
-

EOF

    # Check if CHANGELOG.md exists
    if [[ -f "CHANGELOG.md" ]]; then
        # Insert new entry after the header
        if grep -q "# Changelog" CHANGELOG.md; then
            # Find the line number after the header
            local header_line=$(grep -n "# Changelog" CHANGELOG.md | head -1 | cut -d: -f1)
            local insert_line=$((header_line + 2))

            # Create new changelog
            head -n $header_line CHANGELOG.md > /tmp/new_changelog
            echo "" >> /tmp/new_changelog
            cat /tmp/changelog_entry >> /tmp/new_changelog
            tail -n +$((insert_line)) CHANGELOG.md >> /tmp/new_changelog

            mv /tmp/new_changelog CHANGELOG.md
        else
            # No header found, prepend to file
            cat /tmp/changelog_entry CHANGELOG.md > /tmp/new_changelog
            mv /tmp/new_changelog CHANGELOG.md
        fi
    else
        # Create new CHANGELOG.md
        cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

$(cat /tmp/changelog_entry)
EOF
    fi

    rm -f /tmp/changelog_entry

    warn "Please edit CHANGELOG.md to add details about this release"
    if confirm "Open CHANGELOG.md in editor now?"; then
        ${EDITOR:-nano} CHANGELOG.md
    fi
}

# Create git tag and push
create_and_push_tag() {
    local version="$1"
    local message="$2"

    log "Creating and pushing tag $version..."

    # Add updated files
    git add CHANGELOG.md

    # Commit changes
    git commit -m "Release $version

$message" || warn "No changes to commit"

    # Create tag
    git tag -a "$version" -m "Release $version

$message"

    # Push changes and tag
    git push origin main
    git push origin "$version"

    success "Tagged and pushed $version"
}

# Get SHA of the latest tag
get_tag_sha() {
    local version="$1"
    git rev-list -n 1 "$version"
}

# Update Homebrew formula
update_homebrew_formula() {
    local version="$1"
    local sha="$2"

    log "Updating Homebrew formula..."

    cd "$HOMEBREW_REPO_DIR"

    # Clean the SHA value - remove any whitespace/newlines
    sha=$(echo "$sha" | tr -d '\n\r\t ' | head -c 64)

    # Validate the SHA is exactly 64 hex characters
    if [[ ! "$sha" =~ ^[a-f0-9]{64}$ ]]; then
        error "Invalid SHA256 format: '$sha'"
    fi

    log "Using SHA256: $sha"

    # Update URL first
    sed -i.bak \
        "s|url \".*\"|url \"https://github.com/jtanium/mac-rebuild/archive/refs/tags/$version.tar.gz\"|" \
        "$FORMULA_FILE"

    # Update SHA256 using a different approach - use awk to avoid sed issues
    awk -v new_sha="$sha" '
        /^  sha256 / {
            print "  sha256 \"" new_sha "\""
            next
        }
        { print }
    ' "$FORMULA_FILE" > "$FORMULA_FILE.tmp" && mv "$FORMULA_FILE.tmp" "$FORMULA_FILE"

    # Remove backup file
    rm -f "$FORMULA_FILE.bak"

    # Show the changes
    log "Formula changes:"
    git diff "$FORMULA_FILE"

    cd "$MAIN_REPO_DIR"

    success "Updated Homebrew formula"
}

# Calculate SHA256 of the release tarball
calculate_tarball_sha() {
    local version="$1"
    local url="https://github.com/jtanium/mac-rebuild/archive/refs/tags/$version.tar.gz"

    # Create a temporary file to store the download
    local temp_file="/tmp/mac_rebuild_tarball_$$"

    # Write to stderr to avoid contamination, then redirect to /dev/null in the main script
    echo "Downloading tarball from $url..." >&2

    # Download to temporary file first
    if ! curl -sL "$url" -o "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        return 1
    fi

    # Calculate SHA256 from the file
    local sha
    sha=$(shasum -a 256 "$temp_file" 2>/dev/null | cut -d' ' -f1)

    # Clean up temporary file
    rm -f "$temp_file"

    # Clean the SHA and validate
    sha=$(echo "$sha" | tr -d '\n\r\t ' | head -c 64)

    if [[ ! "$sha" =~ ^[a-f0-9]{64}$ ]]; then
        echo "Failed to calculate SHA256" >&2
        return 1
    fi

    # Only output the SHA to stdout
    echo "$sha"
}

# Commit and push Homebrew formula changes
commit_and_push_formula() {
    local version="$1"

    log "Committing and pushing Homebrew formula changes..."

    cd "$HOMEBREW_REPO_DIR"

    # Ensure we're in the right directory and the file exists
    if [[ ! -f "Formula/mac-rebuild.rb" ]]; then
        cd "$MAIN_REPO_DIR"
        error "Formula file not found in homebrew repository: $HOMEBREW_REPO_DIR/Formula/mac-rebuild.rb"
    fi

    # Add the formula file using relative path
    git add Formula/mac-rebuild.rb
    git commit -m "Update mac-rebuild to $version"
    git push origin main

    cd "$MAIN_REPO_DIR"

    success "Pushed Homebrew formula changes"
}

# Main release function
main() {
    echo "🚀 Mac Rebuild Release Automation"
    echo "=================================="

    # Parse arguments
    local version_type="${1:-patch}"
    local custom_version="$2"

    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        cat << EOF
Usage: $0 [VERSION_TYPE] [CUSTOM_VERSION]

VERSION_TYPE can be:
  patch (default) - Increment patch version (1.0.0 -> 1.0.1)
  minor          - Increment minor version (1.0.0 -> 1.1.0)
  major          - Increment major version (1.0.0 -> 2.0.0)
  custom         - Use CUSTOM_VERSION exactly as provided

CUSTOM_VERSION:
  Only used when VERSION_TYPE is 'custom'
  Should be in format: v1.2.3

Examples:
  $0                    # Patch release
  $0 minor             # Minor release
  $0 major             # Major release
  $0 custom v2.0.0     # Custom version

EOF
        exit 0
    fi

    # Validate environment
    validate_environment

    # Determine new version
    local current_version=$(get_current_version)
    local new_version

    if [[ "$version_type" == "custom" ]]; then
        if [[ -z "$custom_version" ]]; then
            error "Custom version not provided"
        fi
        new_version="$custom_version"
    else
        new_version=$(increment_version "$current_version" "$version_type")
    fi

    log "Current version: $current_version"
    log "New version: $new_version"

    if ! confirm "Proceed with release $new_version?"; then
        warn "Release cancelled"
        exit 0
    fi

    # Get release notes
    echo "Enter release notes (press Ctrl+D when done):"
    local release_notes=$(cat)

    # Update changelog
    update_changelog "$new_version"

    # Create and push tag
    create_and_push_tag "$new_version" "$release_notes"

    # Wait a moment for GitHub to process the tag
    log "Waiting for GitHub to process the tag..."
    sleep 10

    # Calculate SHA256 of release tarball
    log "Calculating SHA256 for release tarball..."
    local tarball_sha
    tarball_sha=$(calculate_tarball_sha "$new_version" 2>/dev/null)

    if [[ -z "$tarball_sha" ]]; then
        error "Failed to calculate SHA256 for release tarball"
    fi

    log "Calculated SHA256: $tarball_sha"

    # Update Homebrew formula
    update_homebrew_formula "$new_version" "$tarball_sha"

    # Show formula changes and confirm
    if confirm "Commit and push Homebrew formula changes?"; then
        commit_and_push_formula "$new_version"
    else
        warn "Homebrew formula updated but not committed. Please review and commit manually."
    fi

    echo ""
    success "🎉 Release $new_version completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Verify the release on GitHub: https://github.com/jtanium/mac-rebuild/releases/tag/$new_version"
    echo "  2. Test the Homebrew formula: brew install jtanium/mac-rebuild/mac-rebuild"
    echo "  3. Create GitHub release notes if desired"
}

# Run main function with all arguments
main "$@"
