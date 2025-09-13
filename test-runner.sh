#!/bin/bash

# Mac Rebuild Test Runner
# Easy way to run all tests locally using Docker

set -e

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

# Function to build test image
build_test_image() {
    log_info "Building Mac Rebuild test image..."

    if docker build -f tests/Dockerfile -t mac-rebuild:test . > /tmp/docker-build.log 2>&1; then
        log_success "Test image built successfully"
    else
        log_error "Failed to build test image"
        echo "Build log:"
        cat /tmp/docker-build.log
        exit 1
    fi
}

# Function to run unit tests
run_unit_tests() {
    log_info "Running unit tests..."

    if docker run --rm mac-rebuild:test test; then
        log_success "Unit tests passed"
    else
        log_error "Unit tests failed"
        exit 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    log_info "Running integration tests..."

    if docker run --rm -v "$(pwd)/tests:/tests" mac-rebuild:test sh -c "cd /tests && bash integration-tests.sh"; then
        log_success "Integration tests passed"
    else
        log_error "Integration tests failed"
        exit 1
    fi
}

# Function to run interactive test environment
run_interactive() {
    log_info "Starting interactive test environment..."
    log_info "You can run commands like 'mac-rebuild --help' or 'mac-rebuild plugins'"

    docker run --rm -it mac-rebuild:test interactive
}

# Function to run specific test
run_specific_test() {
    local test_command="$1"
    log_info "Running specific test: $test_command"

    docker run --rm mac-rebuild:test sh -c "$test_command"
}

# Function to clean up test artifacts
cleanup() {
    log_info "Cleaning up test artifacts..."

    # Remove test image
    if docker image inspect mac-rebuild:test >/dev/null 2>&1; then
        docker rmi mac-rebuild:test >/dev/null 2>&1 || true
        log_success "Test image removed"
    fi

    # Remove temporary files
    rm -f /tmp/docker-build.log /tmp/backup.log /tmp/restore.log

    log_success "Cleanup completed"
}

# Show usage
show_usage() {
    echo "Mac Rebuild Test Runner"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  all           Run all tests (unit + integration)"
    echo "  unit          Run unit tests only"
    echo "  integration   Run integration tests only"
    echo "  interactive   Start interactive test environment"
    echo "  build         Build test image only"
    echo "  clean         Clean up test artifacts"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all                    # Run all tests"
    echo "  $0 interactive            # Start interactive shell"
    echo "  $0 unit                   # Run unit tests only"
    echo ""
}

# Main execution
main() {
    local command="${1:-all}"

    case "$command" in
        "all")
            echo "🚀 Running all Mac Rebuild tests"
            echo "================================"
            build_test_image
            run_unit_tests
            run_integration_tests
            log_success "All tests completed successfully!"
            ;;
        "unit")
            echo "🧪 Running unit tests"
            echo "===================="
            build_test_image
            run_unit_tests
            ;;
        "integration")
            echo "🔬 Running integration tests"
            echo "============================"
            build_test_image
            run_integration_tests
            ;;
        "interactive")
            build_test_image
            run_interactive
            ;;
        "build")
            build_test_image
            ;;
        "clean")
            cleanup
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
