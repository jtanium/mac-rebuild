# Testing Guide for Mac Rebuild

This document describes the comprehensive automated testing framework for Mac Rebuild v2.0.

## 🧪 Testing Overview

Mac Rebuild now includes a robust Docker-based testing framework that provides:

- **Unit Tests**: Core functionality validation
- **Integration Tests**: Full backup/restore cycle testing
- **Plugin Tests**: Individual plugin functionality
- **Error Handling Tests**: Edge cases and failure scenarios
- **CI/CD Integration**: Automated testing on every commit

## 🚀 Quick Start

### Run All Tests
```bash
./test-runner.sh all
```

### Run Specific Test Types
```bash
./test-runner.sh unit          # Unit tests only
./test-runner.sh integration   # Integration tests only
./test-runner.sh interactive   # Interactive test environment
```

### Clean Up
```bash
./test-runner.sh clean
```

## 🐳 Docker-Based Testing

### Why Docker?

Since Mac Rebuild is designed for macOS, testing on other platforms is challenging. Our Docker-based approach:

- ✅ **Cross-platform**: Run tests on Linux, macOS, Windows
- ✅ **Consistent environment**: Every test runs in identical conditions  
- ✅ **Isolated**: Tests don't affect your system
- ✅ **CI/CD ready**: Perfect for GitHub Actions
- ✅ **Reproducible**: Same results every time

### Test Environment

The Docker container simulates a macOS-like environment with:

- Ubuntu 22.04 base (closest to macOS shell behavior)
- Homebrew Linux installation
- Mock macOS directory structure (`~/Library/`, etc.)
- Realistic development tools and configurations
- SSH keys, dotfiles, and application preferences

## 📋 Test Suites

### 1. Unit Tests (`tests/run-tests.sh`)

**What it tests:**
- Basic command functionality (`--version`, `--help`)
- Plugin system loading and listing
- Backup command execution
- Restore command execution
- Error handling for invalid inputs
- File structure verification

**Mock data created:**
- SSH keys and configuration
- Dotfiles (`.zshrc`, `.gitconfig`, `.npmrc`)
- VS Code settings
- Application preferences
- ASDF tool versions
- Homebrew-like structure

### 2. Integration Tests (`tests/integration-tests.sh`)

**What it tests:**
- Full backup → restore cycle
- Realistic development environment setup
- Plugin interactions
- Data integrity across backup/restore
- Complex configurations (multiple SSH keys, etc.)
- Error conditions and edge cases

**Realistic scenarios:**
- Developer with GitHub + GitLab SSH keys
- Node.js + Python + Ruby development setup
- VS Code with custom settings
- Multiple application preferences

### 3. Plugin Tests

Each plugin is tested for:
- Detection functionality
- Backup creation
- Restore execution
- Error handling
- File permissions
- Content integrity

## 🔧 Test Configuration

### Environment Variables

The testing system uses these environment variables:

```bash
MAC_REBUILD_NON_INTERACTIVE=1    # Skip interactive prompts
MAC_REBUILD_BACKUP_DIR=/path     # Override backup directory
HOME=/test/home                  # Test home directory
```

### Test Directory Structure

```
tests/
├── Dockerfile                   # Test container definition
├── docker-entrypoint.sh        # Container entry point
├── run-tests.sh                 # Unit test suite
├── integration-tests.sh         # Integration test suite
└── README.md                    # This documentation
```

## 🏃‍♂️ Running Tests Locally

### Prerequisites

- Docker installed and running
- Mac Rebuild source code

### Step-by-Step

1. **Build and run all tests:**
   ```bash
   ./test-runner.sh all
   ```

2. **Interactive testing:**
   ```bash
   ./test-runner.sh interactive
   # Inside container:
   mac-rebuild --help
   mac-rebuild plugins
   mac-rebuild backup
   ```

3. **Debug specific issues:**
   ```bash
   # Build image
   ./test-runner.sh build
   
   # Run specific command
   docker run --rm mac-rebuild:test sh -c "mac-rebuild plugins"
   ```

## 🤖 CI/CD Integration

### GitHub Actions

The `.github/workflows/test.yml` workflow:

1. **Builds** the Docker test image
2. **Runs** all test suites
3. **Validates** basic commands work
4. **Performs** security scanning with ShellCheck
5. **Runs** integration tests

### Triggered On

- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual workflow dispatch

## 🔍 Test Output Examples

### Successful Test Run
```
🚀 Starting Mac Rebuild Test Suite
==================================

🧪 TEST: Basic Commands
✅ PASS: Version command works
✅ PASS: Help command works

🧪 TEST: Plugin System Functionality  
✅ PASS: Plugin listing command works
✅ PASS: Core plugin 'homebrew' is available
✅ PASS: Core plugin 'dotfiles' is available

📊 Test Results
===============
Total tests run: 15
Passed: 15
Failed: 0

🎉 All tests passed!
```

### Failed Test Run
```
🧪 TEST: Backup Functionality
❌ FAIL: Backup command failed
Backup log:
Error: Could not create backup directory

📊 Test Results  
===============
Total tests run: 10
Passed: 8
Failed: 2

💥 Some tests failed!
```

## 🐛 Debugging Test Failures

### 1. Check Test Logs

Test outputs are saved to temporary files:
- `/tmp/backup.log`
- `/tmp/restore.log`
- `/tmp/docker-build.log`

### 2. Interactive Debugging

```bash
./test-runner.sh interactive

# Inside container, run commands manually:
mac-rebuild backup
ls -la /tmp/mac-rebuild-tests/
```

### 3. Plugin-Specific Issues

```bash
# Test individual plugin
docker run --rm mac-rebuild:test sh -c "
  source /opt/mac-rebuild/lib/mac-rebuild/plugin-system.sh
  homebrew_backup
"
```

### 4. File Permission Issues

```bash
# Check file permissions in test
docker run --rm mac-rebuild:test sh -c "
  ls -la ~/.ssh/
  ls -la ~/.config/
"
```

## 📈 Adding New Tests

### 1. Unit Tests

Add to `tests/run-tests.sh`:

```bash
test_my_new_feature() {
    log_test "My New Feature"
    
    if mac-rebuild my-command > /dev/null 2>&1; then
        log_pass "My command works"
    else
        log_fail "My command failed"
    fi
}

# Add to main() function:
test_my_new_feature
```

### 2. Integration Tests

Add to `tests/integration-tests.sh`:

```bash
test_my_integration() {
    log_info "Testing my integration..."
    
    # Setup test data
    # Run commands
    # Verify results
    
    log_success "Integration test passed"
}
```

### 3. Plugin Tests

Create plugin-specific test functions:

```bash
test_plugin_my_tool() {
    log_test "My Tool Plugin"
    
    # Test plugin detection
    # Test backup functionality  
    # Test restore functionality
    # Test error conditions
}
```

## 🔒 Security Testing

### ShellCheck Integration

All shell scripts are automatically checked with ShellCheck:

```bash
# Run locally
shellcheck mac-rebuild
find . -name "*.sh" -exec shellcheck {} \;
```

### Mock Sensitive Data

Tests use mock data for:
- SSH keys (not real private keys)
- API tokens (fake tokens)
- Personal information (test data only)

## 📊 Test Coverage

Current test coverage includes:

### ✅ Covered
- Basic command execution
- Plugin system functionality
- Backup/restore cycles
- Error handling
- File permissions
- Cross-plugin interactions

### 🔄 Future Enhancements
- Performance benchmarking
- Memory usage testing
- Concurrent operation testing
- Plugin dependency testing
- Rollback functionality testing

## 🤝 Contributing Tests

When contributing new features:

1. **Add unit tests** for new commands
2. **Add integration tests** for complex workflows
3. **Test error conditions** and edge cases
4. **Verify backward compatibility**
5. **Update documentation**

### Test Naming Convention

```bash
test_feature_description()           # Unit tests
test_integration_scenario()         # Integration tests
test_plugin_name_functionality()    # Plugin tests
test_error_condition_description()  # Error tests
```

## 🎯 Best Practices

### 1. Test Isolation
- Each test should be independent
- Clean up after tests
- Use temporary directories

### 2. Realistic Data
- Use representative configurations
- Test with complex scenarios
- Include edge cases

### 3. Clear Output
- Use descriptive test names
- Provide helpful error messages
- Log important steps

### 4. Fast Execution
- Parallel test execution where possible
- Mock external dependencies
- Optimize Docker image size

---

## 📞 Getting Help

If you encounter testing issues:

1. **Check this documentation**
2. **Run tests in interactive mode**
3. **Check CI/CD logs on GitHub**
4. **Open an issue with test output**

The testing framework is designed to catch issues before they reach production, giving us confidence in Mac Rebuild's reliability across different environments and use cases.
