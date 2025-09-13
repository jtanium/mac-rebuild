#!/bin/bash

# Mac Rebuild Test Suite Runner
# Runs unit tests and integration tests

set -e

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to run unit tests
run_unit_tests() {
    log_info "Running Mac Rebuild unit tests..."

    local test_failures=0

    # Test 1: Basic command availability
    if command -v mac-rebuild >/dev/null 2>&1; then
        log_success "mac-rebuild command is available"
    else
        log_error "mac-rebuild command not found"
        test_failures=$((test_failures + 1))
    fi

    # Test 2: Help command
    if mac-rebuild --help >/dev/null 2>&1; then
        log_success "Help command works"
    else
        log_error "Help command failed"
        test_failures=$((test_failures + 1))
    fi

    # Test 3: Version command
    if mac-rebuild --version >/dev/null 2>&1; then
        log_success "Version command works"
    else
        log_error "Version command failed"
        test_failures=$((test_failures + 1))
    fi

    # Test 4: Plugin listing
    if mac-rebuild plugins >/dev/null 2>&1; then
        log_success "Plugin listing works"
    else
        log_error "Plugin listing failed"
        test_failures=$((test_failures + 1))
    fi

    # Test 5: Library directory structure
    if [ -d "$PROJECT_DIR/lib/mac-rebuild" ]; then
        log_success "Library directory structure exists"
    else
        log_error "Library directory structure missing"
        test_failures=$((test_failures + 1))
    fi

    # Test 6: Core plugin files exist
    local core_plugins=("dotfiles" "homebrew" "ssh" "vscode")
    local missing_plugins=0

    for plugin in "${core_plugins[@]}"; do
        if [ -f "$PROJECT_DIR/lib/mac-rebuild/plugins/${plugin}.sh" ]; then
            log_success "Core plugin $plugin exists"
        else
            log_error "Core plugin $plugin missing"
            missing_plugins=$((missing_plugins + 1))
        fi
    done

    if [ $missing_plugins -eq 0 ]; then
        log_success "All core plugins present"
    else
        test_failures=$((test_failures + 1))
    fi

    # Test 7: Configuration validation
    if [ -f "$PROJECT_DIR/lib/mac-rebuild/config.sh" ]; then
        log_success "Configuration file exists"

        # Source and validate config
        if source "$PROJECT_DIR/lib/mac-rebuild/config.sh" >/dev/null 2>&1; then
            log_success "Configuration file is valid"
        else
            log_error "Configuration file has syntax errors"
            test_failures=$((test_failures + 1))
        fi
    else
        log_error "Configuration file missing"
        test_failures=$((test_failures + 1))
    fi

    # Test 8: Plugin system validation
    if [ -f "$PROJECT_DIR/lib/mac-rebuild/plugin-system.sh" ]; then
        log_success "Plugin system file exists"

        # Source and validate plugin system
        if source "$PROJECT_DIR/lib/mac-rebuild/plugin-system.sh" >/dev/null 2>&1; then
            log_success "Plugin system file is valid"
        else
            log_error "Plugin system file has syntax errors"
            test_failures=$((test_failures + 1))
        fi
    else
        log_error "Plugin system file missing"
        test_failures=$((test_failures + 1))
    fi

    if [ $test_failures -eq 0 ]; then
        log_success "All unit tests passed"
        return 0
    else
        log_error "$test_failures unit tests failed"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    log_info "Running Mac Rebuild integration tests..."

    # Run integration test script
    if [ -f "$TEST_DIR/integration-tests.sh" ]; then
        if bash "$TEST_DIR/integration-tests.sh"; then
            log_success "Integration tests passed"
            return 0
        else
            log_error "Integration tests failed"
            return 1
        fi
    else
        log_error "Integration test script not found"
        return 1
    fi
}

# Main test execution
main() {
    echo "🧪 Mac Rebuild Test Suite"
    echo "========================="
    echo ""

    local total_failures=0

    # Run unit tests
    if ! run_unit_tests; then
        total_failures=$((total_failures + 1))
    fi

    echo ""

    # Run integration tests
    if ! run_integration_tests; then
        total_failures=$((total_failures + 1))
    fi

    echo ""
    echo "🏁 Test Summary"
    echo "==============="

    if [ $total_failures -eq 0 ]; then
        log_success "All tests passed successfully!"
        exit 0
    else
        log_error "$total_failures test suite(s) failed"
        exit 1
    fi
}

# Run main function
main "$@"
