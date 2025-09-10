#!/bin/bash

# Quick release script for common patch releases
# Usage: ./quick-release.sh [release_notes]

set -e

RELEASE_NOTES="${1:-Minor updates and improvements}"

echo "🚀 Quick Patch Release"
echo "====================="
echo "Release notes: $RELEASE_NOTES"
echo ""

if [[ ! "$*" =~ --yes ]]; then
    read -p "Proceed with patch release? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled"
        exit 0
    fi
fi

# Run the full release script with patch version and release notes
echo "$RELEASE_NOTES" | ./release.sh patch

echo ""
echo "✅ Quick patch release completed!"
