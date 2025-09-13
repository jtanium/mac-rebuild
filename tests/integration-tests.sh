#!/bin/bash

# Integration Tests for Mac Rebuild
# Tests real-world scenarios and plugin interactions

set -e

# Test configuration
INTEGRATION_DIR="/tmp/mac-rebuild-integration"
TEST_BACKUP_DIR="$INTEGRATION_DIR/backup"
TEST_RESTORE_DIR="$INTEGRATION_DIR/restore"

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

# Setup integration test environment
setup_integration_environment() {
    log_info "Setting up integration test environment..."

    rm -rf "$INTEGRATION_DIR"
    mkdir -p "$INTEGRATION_DIR" "$TEST_BACKUP_DIR" "$TEST_RESTORE_DIR"

    # Create realistic development environment
    setup_realistic_dev_environment

    log_success "Integration environment ready"
}

# Create a realistic development environment for testing
setup_realistic_dev_environment() {
    log_info "Creating realistic development environment..."

    # SSH configuration with multiple keys
    mkdir -p "$HOME/.ssh"
    cat > "$HOME/.ssh/config" << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_github

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_rsa_gitlab

Host *
    AddKeysToAgent yes
    UseKeychain yes
EOF

    # Generate mock SSH keys
    echo "-----BEGIN RSA PRIVATE KEY-----" > "$HOME/.ssh/id_rsa_github"
    echo "mock-github-private-key-content" >> "$HOME/.ssh/id_rsa_github"
    echo "-----END RSA PRIVATE KEY-----" >> "$HOME/.ssh/id_rsa_github"
    echo "ssh-rsa AAAAB3NzaC1yc2E...github-key user@github" > "$HOME/.ssh/id_rsa_github.pub"
    chmod 600 "$HOME/.ssh/id_rsa_github" "$HOME/.ssh/config"
    chmod 644 "$HOME/.ssh/id_rsa_github.pub"

    # Comprehensive dotfiles
    cat > "$HOME/.zshrc" << 'EOF'
# Mac Rebuild Test .zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Development paths
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.asdf/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# Aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

# Development aliases
alias gc='git commit'
alias gs='git status'
alias gp='git push'
alias gl='git log --oneline'

# Export environment variables
export EDITOR=vim
export LANG=en_US.UTF-8
export GPG_TTY=$(tty)
EOF

    cat > "$HOME/.gitconfig" << 'EOF'
[user]
    name = Integration Test User
    email = integration@test.com
    signingkey = ABC123DEF456

[core]
    editor = vim
    autocrlf = input
    excludesfile = ~/.gitignore_global

[push]
    default = simple
    autoSetupRemote = true

[pull]
    rebase = false

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate

[commit]
    gpgsign = true
EOF

    # Node.js development environment
    cat > "$HOME/.npmrc" << 'EOF'
registry=https://registry.npmjs.org/
@mycompany:registry=https://npm.mycompany.com/
//npm.mycompany.com/:_authToken=mock-auth-token
save-exact=true
package-lock=true
EOF

    # ASDF tool versions
    cat > "$HOME/.tool-versions" << 'EOF'
nodejs 18.17.0
python 3.11.4
ruby 3.2.2
golang 1.20.6
terraform 1.5.2
kubectl 1.27.3
EOF

    # VS Code settings
    mkdir -p "$HOME/.vscode"
    cat > "$HOME/.vscode/settings.json" << 'EOF'
{
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.renderWhitespace": "boundary",
    "editor.rulers": [80, 120],
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "terminal.integrated.fontSize": 12,
    "workbench.colorTheme": "Dark+ (default dark)",
    "git.autofetch": true,
    "extensions.autoUpdate": false
}
EOF

    # Mock application preferences
    mkdir -p "$HOME/Library/Preferences" "$HOME/Library/Application Support"
    echo '{"theme": "dark", "fontSize": 14}' > "$HOME/Library/Preferences/com.microsoft.VSCode.plist"
    echo '{"connections": [{"name": "test", "host": "localhost"}]}' > "$HOME/Library/Preferences/com.tableplus.plist"

    log_success "Realistic development environment created"
}

# Test full backup and restore cycle
test_full_backup_restore_cycle() {
    log_info "Testing full backup and restore cycle..."

    # Perform backup
    export MAC_REBUILD_NON_INTERACTIVE=1
    export MAC_REBUILD_BACKUP_DIR="$TEST_BACKUP_DIR"

    log_info "Running backup..."
    if mac-rebuild backup > "$INTEGRATION_DIR/backup.log" 2>&1; then
        log_success "Backup completed successfully"
    else
        log_error "Backup failed"
        cat "$INTEGRATION_DIR/backup.log"
        return 1
    fi

    # Verify backup structure
    verify_backup_structure

    # Clean environment for restore test
    backup_original_files
    clean_environment_for_restore

    # Perform restore
    log_info "Running restore..."
    if mac-rebuild restore "$TEST_BACKUP_DIR" > "$INTEGRATION_DIR/restore.log" 2>&1; then
        log_success "Restore completed successfully"
    else
        log_error "Restore failed"
        cat "$INTEGRATION_DIR/restore.log"
        return 1
    fi

    # Verify restore results
    verify_restore_results

    log_success "Full backup and restore cycle completed successfully"
}

# Verify backup structure contains expected data
verify_backup_structure() {
    log_info "Verifying backup structure..."

    local backup_items_found=0

    # Check for key backup components
    if [ -d "$TEST_BACKUP_DIR/dotfiles" ] || find "$TEST_BACKUP_DIR" -name "*zshrc*" | grep -q .; then
        log_success "Dotfiles backed up"
        backup_items_found=$((backup_items_found + 1))
    fi

    if [ -d "$TEST_BACKUP_DIR/ssh" ] || find "$TEST_BACKUP_DIR" -name "*ssh*" | grep -q .; then
        log_success "SSH configuration backed up"
        backup_items_found=$((backup_items_found + 1))
    fi

    if [ -d "$TEST_BACKUP_DIR/vscode" ] || find "$TEST_BACKUP_DIR" -name "*vscode*" | grep -q .; then
        log_success "VS Code settings backed up"
        backup_items_found=$((backup_items_found + 1))
    fi

    if [ $backup_items_found -eq 0 ]; then
        log_error "No backup items found in backup directory"
        return 1
    fi

    log_success "Backup structure verification passed ($backup_items_found items found)"
}

# Backup original files before cleaning for restore test
backup_original_files() {
    mkdir -p "$INTEGRATION_DIR/originals"
    cp -r "$HOME/.ssh" "$INTEGRATION_DIR/originals/" 2>/dev/null || true
    cp "$HOME/.zshrc" "$INTEGRATION_DIR/originals/" 2>/dev/null || true
    cp "$HOME/.gitconfig" "$INTEGRATION_DIR/originals/" 2>/dev/null || true
}

# Clean environment to test restore
clean_environment_for_restore() {
    log_info "Cleaning environment for restore test..."

    # Remove configuration files
    rm -f "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.npmrc" "$HOME/.tool-versions"
    rm -rf "$HOME/.ssh" "$HOME/.vscode"
    rm -rf "$HOME/Library/Preferences"/* 2>/dev/null || true

    log_success "Environment cleaned for restore test"
}

# Verify restore results
verify_restore_results() {
    log_info "Verifying restore results..."

    local restore_items_found=0

    # Check restored files
    if [ -f "$HOME/.zshrc" ]; then
        log_success "Shell configuration restored"
        restore_items_found=$((restore_items_found + 1))
    fi

    if [ -f "$HOME/.gitconfig" ]; then
        log_success "Git configuration restored"
        restore_items_found=$((restore_items_found + 1))
    fi

    if [ -d "$HOME/.ssh" ] && [ -f "$HOME/.ssh/config" ]; then
        log_success "SSH configuration restored"
        restore_items_found=$((restore_items_found + 1))
    fi

    if [ -f "$HOME/.npmrc" ]; then
        log_success "NPM configuration restored"
        restore_items_found=$((restore_items_found + 1))
    fi

    if [ $restore_items_found -eq 0 ]; then
        log_error "No configuration files were restored"
        return 1
    fi

    # Verify file contents (sample check)
    if grep -q "Integration Test User" "$HOME/.gitconfig" 2>/dev/null; then
        log_success "Restored files contain expected content"
    else
        log_warning "Restored files may not contain expected content"
    fi

    log_success "Restore verification passed ($restore_items_found items found)"
}

# Test plugin system integration
test_plugin_integration() {
    log_info "Testing plugin system integration..."

    # Test that plugins can be listed
    local plugin_output=$(mac-rebuild plugins 2>/dev/null)
    if [ -n "$plugin_output" ]; then
        log_success "Plugin system is functional"

        # Count plugins
        local plugin_count=$(echo "$plugin_output" | grep -c "📦" 2>/dev/null || echo "0")
        log_info "Found $plugin_count plugins"

        if [ "$plugin_count" -gt 0 ]; then
            log_success "Plugin system has plugins available"
        else
            log_warning "No plugins found in system"
        fi
    else
        log_error "Plugin system is not responding"
        return 1
    fi
}

# Test error conditions
test_error_conditions() {
    log_info "Testing error conditions..."

    # Test restore with non-existent backup
    if mac-rebuild restore "/non/existent/path" >/dev/null 2>&1; then
        log_error "Should have failed with non-existent backup path"
    else
        log_success "Correctly handles non-existent backup path"
    fi

    # Test invalid commands
    if mac-rebuild invalid-command >/dev/null 2>&1; then
        log_error "Should have failed with invalid command"
        return 1
    else
        log_success "Correctly handles invalid commands"
    fi

    # Test backup without write permissions (simulate)
    export MAC_REBUILD_BACKUP_DIR="/root/no-permission"
    if mac-rebuild backup >/dev/null 2>&1; then
        log_warning "Backup should have failed with permission denied"
    else
        log_success "Correctly handles permission issues"
    fi
    unset MAC_REBUILD_BACKUP_DIR

    log_success "Error condition tests passed"
}

# Test environment simulation for Docker
test_docker_environment_simulation() {
    log_info "Testing Docker environment simulation..."

    # Mock Time Machine availability check
    if [ "$MAC_REBUILD_TEST_MODE" = "1" ]; then
        log_success "Test mode is enabled"

        # Create mock Time Machine backup
        mkdir -p /tmp/mock-time-machine-backup
        echo "Mock backup data" > /tmp/mock-time-machine-backup/backup.marker
        echo '{"BackupAlias": "Mock Backup"}' > /tmp/mock-time-machine-backup/com.apple.TimeMachine.plist

        log_success "Mock Time Machine backup created"

        # Simulate backup data availability
        export MAC_REBUILD_MOCK_TIME_MACHINE_PATH="/tmp/mock-time-machine-backup"
        log_success "Time Machine simulation configured"
    else
        log_warning "Not running in test mode - some tests may fail on macOS"
    fi
}

# Performance test for backup/restore operations
test_performance() {
    log_info "Running performance tests..."

    local start_time
    local end_time
    local duration

    # Test backup performance
    start_time=$(date +%s)
    export MAC_REBUILD_NON_INTERACTIVE=1
    export MAC_REBUILD_BACKUP_DIR="$INTEGRATION_DIR/perf-backup"

    if mac-rebuild backup >/dev/null 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))

        if [ $duration -lt 30 ]; then
            log_success "Backup completed in ${duration}s (good performance)"
        elif [ $duration -lt 60 ]; then
            log_warning "Backup completed in ${duration}s (acceptable performance)"
        else
            log_warning "Backup completed in ${duration}s (slow performance)"
        fi
    else
        log_error "Performance backup test failed"
        return 1
    fi

    # Test restore performance
    start_time=$(date +%s)
    if mac-rebuild restore "$INTEGRATION_DIR/perf-backup" >/dev/null 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))

        if [ $duration -lt 20 ]; then
            log_success "Restore completed in ${duration}s (good performance)"
        elif [ $duration -lt 40 ]; then
            log_warning "Restore completed in ${duration}s (acceptable performance)"
        else
            log_warning "Restore completed in ${duration}s (slow performance)"
        fi
    else
        log_error "Performance restore test failed"
        return 1
    fi

    log_success "Performance tests completed"
}

# Main execution function
main() {
    echo "🔬 Mac Rebuild Integration Tests"
    echo "================================"
    echo ""

    local test_failures=0

    # Setup test environment
    setup_integration_environment

    # Test Docker environment simulation (if in Docker)
    test_docker_environment_simulation

    # Run test suites
    log_info "Running integration test suites..."
    echo ""

    # Test 1: Full backup and restore cycle
    if ! test_full_backup_restore_cycle; then
        test_failures=$((test_failures + 1))
        log_error "Full backup/restore cycle test failed"
    fi
    echo ""

    # Test 2: Plugin system integration
    if ! test_plugin_integration; then
        test_failures=$((test_failures + 1))
        log_error "Plugin integration test failed"
    fi
    echo ""

    # Test 3: Error conditions
    if ! test_error_conditions; then
        test_failures=$((test_failures + 1))
        log_error "Error conditions test failed"
    fi
    echo ""

    # Test 4: Performance tests
    if ! test_performance; then
        test_failures=$((test_failures + 1))
        log_error "Performance test failed"
    fi
    echo ""

    # Summary
    echo "🏁 Integration Test Results"
    echo "============================"

    if [ $test_failures -eq 0 ]; then
        log_success "All integration tests passed!"

        # Clean up test artifacts
        log_info "Cleaning up test artifacts..."
        rm -rf "$INTEGRATION_DIR" 2>/dev/null || true

        exit 0
    else
        log_error "$test_failures integration test(s) failed"

        # Keep test artifacts for debugging
        log_info "Test artifacts preserved in: $INTEGRATION_DIR"

        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
