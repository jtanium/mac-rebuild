#!/bin/bash

# Docker entrypoint for Mac Rebuild testing
set -e

echo "🐳 Starting Mac Rebuild Docker Test Environment"
echo "================================================"

# Set up environment
export HOME=/home/testuser
export PATH="/opt/mac-rebuild:$PATH"

# Function to run tests
run_tests() {
    echo "🧪 Running Mac Rebuild Tests..."

    cd /opt/mac-rebuild

    # Run test suite
    if [ -f "tests/run-tests.sh" ]; then
        bash tests/run-tests.sh
    else
        echo "❌ Test runner not found!"
        exit 1
    fi
}

# Function to run interactive mode
run_interactive() {
    echo "🔧 Starting interactive test environment..."
    echo "Mac Rebuild is available at: /opt/mac-rebuild"
    echo "Run 'mac-rebuild --help' to get started"
    exec /bin/bash
}

# Function to execute arbitrary commands
run_command() {
    echo "🚀 Executing: $*"
    exec "$@"
}

# Main execution
case "$1" in
    "test")
        run_tests
        ;;
    "interactive")
        run_interactive
        ;;
    "")
        # Default to interactive if no args
        run_interactive
        ;;
    *)
        # Execute the provided command directly
        run_command "$@"
        ;;
esac
