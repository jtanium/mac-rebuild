#!/bin/bash

# ASDF Plugin for Mac Rebuild
# Handles backup and restore of ASDF tools, plugins, and versions

# Plugin metadata
asdf_description() {
    echo "Manages ASDF version manager with enhanced plugin and runtime handling"
}

asdf_priority() {
    echo "20"  # After Homebrew but before applications
}

asdf_init() {
    # Detect Homebrew installation path for ASDF
    if [[ $(uname -m) == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
}

asdf_has_detection() {
    return 0
}

asdf_detect() {
    command -v asdf &> /dev/null
}

asdf_backup() {
    log "Backing up ASDF tools and versions..."

    if ! asdf_detect; then
        echo "⚠️  ASDF not found, skipping..."
        return 0
    fi

    local backup_dir="$BACKUP_DIR/asdf"
    mkdir -p "$backup_dir"

    # Backup current versions
    asdf current > "$backup_dir/current_versions.txt" 2>/dev/null || handle_error "ASDF current" "Could not get current versions"

    # Backup plugins list
    asdf plugin list > "$backup_dir/plugins.txt" 2>/dev/null || handle_error "ASDF plugins" "Could not list plugins"

    # Enhanced: Backup plugin URLs for better restoration
    asdf_backup_plugin_urls "$backup_dir"

    # Enhanced: Backup all installed versions per plugin
    asdf_backup_all_versions "$backup_dir"

    # Backup .tool-versions files
    if [ -f "$HOME/.tool-versions" ]; then
        cp "$HOME/.tool-versions" "$backup_dir/" || handle_error "ASDF tool-versions" "Could not copy .tool-versions"
    fi

    # Backup global .tool-versions if it exists
    if [ -f "$HOME/.asdf/.tool-versions" ]; then
        cp "$HOME/.asdf/.tool-versions" "$backup_dir/.tool-versions-global" || handle_error "ASDF global tool-versions" "Could not copy global .tool-versions"
    fi

    echo "✅ ASDF configuration backed up with enhanced plugin tracking"
}

asdf_backup_plugin_urls() {
    local backup_dir="$1"
    local plugin_urls_file="$backup_dir/plugin_urls.txt"

    echo "# ASDF Plugin URLs for reliable restoration" > "$plugin_urls_file"
    echo "# Format: plugin_name git_repo_url" >> "$plugin_urls_file"

    if [ -f "$backup_dir/plugins.txt" ]; then
        while IFS= read -r plugin; do
            if [ -n "$plugin" ]; then
                local plugin_dir="$HOME/.asdf/plugins/$plugin"
                if [ -d "$plugin_dir/.git" ]; then
                    local repo_url=$(cd "$plugin_dir" && git remote get-url origin 2>/dev/null || echo "")
                    if [ -n "$repo_url" ]; then
                        echo "$plugin $repo_url" >> "$plugin_urls_file"
                    else
                        echo "$plugin" >> "$plugin_urls_file"
                    fi
                else
                    echo "$plugin" >> "$plugin_urls_file"
                fi
            fi
        done < "$backup_dir/plugins.txt"
    fi
}

asdf_backup_all_versions() {
    local backup_dir="$1"
    local versions_file="$backup_dir/all_versions.txt"

    echo "# All installed versions per plugin" > "$versions_file"

    if [ -f "$backup_dir/plugins.txt" ]; then
        while IFS= read -r plugin; do
            if [ -n "$plugin" ]; then
                echo "[$plugin]" >> "$versions_file"
                asdf list "$plugin" 2>/dev/null | grep -v "No versions installed" | sed 's/^[[:space:]]*//' >> "$versions_file" || true
                echo "" >> "$versions_file"
            fi
        done < "$backup_dir/plugins.txt"
    fi
}

asdf_restore() {
    log "Installing and configuring ASDF..."

    local backup_dir="$BACKUP_DIR/asdf"

    if [ ! -f "$backup_dir/plugins.txt" ]; then
        echo "⚠️  No ASDF backup found, skipping..."
        return 0
    fi

    # Install ASDF if not present
    if ! asdf_detect; then
        echo "Installing ASDF..."
        brew install asdf

        # Add ASDF to shell configuration
        echo ". $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh" >> ~/.zshrc

        # Source ASDF for current session
        . "$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh"
        echo "✅ ASDF installed"
    else
        # Make sure ASDF is available in current session
        . "$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh" 2>/dev/null || true
        echo "✅ ASDF already installed"
    fi

    # Install system dependencies
    asdf_install_system_dependencies "$backup_dir"

    # Restore plugins with enhanced URL-based installation
    asdf_restore_plugins "$backup_dir"

    # Restore tool versions
    asdf_restore_versions "$backup_dir"
}

asdf_install_system_dependencies() {
    local backup_dir="$1"

    log "Installing system dependencies for ASDF plugins..."
    echo "This may take a while as we install compilation dependencies..."

    if [ -f "$backup_dir/plugins.txt" ]; then
        while IFS= read -r plugin; do
            if [ -n "$plugin" ]; then
                case "$plugin" in
                    "nodejs")
                        echo "Installing Node.js dependencies..."
                        brew install gpg gawk || true
                        ;;
                    "python")
                        echo "Installing Python dependencies..."
                        brew install openssl readline sqlite3 xz zlib tcl-tk || true
                        ;;
                    "ruby")
                        echo "Installing Ruby dependencies..."
                        brew install openssl readline libyaml gmp || true
                        ;;
                    "erlang")
                        echo "Installing Erlang dependencies..."
                        brew install autoconf openssl wxwidgets libxslt fop || true
                        ;;
                    "elixir")
                        echo "Installing Elixir dependencies (requires Erlang)..."
                        brew install autoconf openssl wxwidgets libxslt fop || true
                        ;;
                    "golang")
                        echo "Go plugin typically doesn't need system dependencies..."
                        ;;
                    "java")
                        echo "Java plugin typically doesn't need system dependencies..."
                        ;;
                    "rust")
                        echo "Installing Rust dependencies..."
                        brew install gcc || true
                        ;;
                    "postgres")
                        echo "Installing PostgreSQL dependencies..."
                        brew install icu4c pkg-config || true
                        ;;
                    *)
                        echo "Unknown plugin dependencies for: $plugin"
                        ;;
                esac
            fi
        done < "$backup_dir/plugins.txt"
    fi
}

asdf_restore_plugins() {
    local backup_dir="$1"

    log "Restoring ASDF plugins with enhanced URL-based installation..."
    local failed_plugins=()

    # Use plugin URLs if available, otherwise fall back to plugin names
    if [ -f "$backup_dir/plugin_urls.txt" ]; then
        while IFS= read -r line; do
            if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
                local plugin_name=$(echo "$line" | awk '{print $1}')
                local plugin_url=$(echo "$line" | awk '{print $2}')

                if [ -n "$plugin_name" ]; then
                    echo "Adding plugin: $plugin_name"
                    if [ -n "$plugin_url" ] && [ "$plugin_url" != "$plugin_name" ]; then
                        # Add plugin with URL
                        if ! asdf plugin add "$plugin_name" "$plugin_url" 2>/dev/null; then
                            echo "⚠️  Failed to add $plugin_name with URL, trying without URL..."
                            if ! asdf plugin add "$plugin_name" 2>/dev/null; then
                                echo "❌ Failed to add plugin: $plugin_name"
                                failed_plugins+=("$plugin_name")
                            fi
                        fi
                    else
                        # Add plugin without URL
                        if ! asdf plugin add "$plugin_name" 2>/dev/null; then
                            echo "❌ Failed to add plugin: $plugin_name"
                            failed_plugins+=("$plugin_name")
                        fi
                    fi
                fi
            fi
        done < "$backup_dir/plugin_urls.txt"
    else
        # Fallback to basic plugin list
        while IFS= read -r plugin; do
            if [ -n "$plugin" ]; then
                echo "Adding plugin: $plugin"
                if ! asdf plugin add "$plugin" 2>/dev/null; then
                    echo "❌ Failed to add plugin: $plugin"
                    failed_plugins+=("$plugin")
                fi
            fi
        done < "$backup_dir/plugins.txt"
    fi

    # Report failed plugins
    if [ ${#failed_plugins[@]} -gt 0 ]; then
        echo "⚠️  The following plugins failed to install:"
        printf '   - %s\n' "${failed_plugins[@]}"
        echo "   You may need to install them manually later."
    fi
}

asdf_restore_versions() {
    local backup_dir="$1"

    # Restore .tool-versions files
    if [ -f "$backup_dir/.tool-versions" ]; then
        echo "Restoring .tool-versions file..."
        cp "$backup_dir/.tool-versions" "$HOME/" || handle_error "ASDF tool-versions" "Could not restore .tool-versions"
    fi

    if [ -f "$backup_dir/.tool-versions-global" ]; then
        echo "Restoring global .tool-versions file..."
        mkdir -p "$HOME/.asdf"
        cp "$backup_dir/.tool-versions-global" "$HOME/.asdf/.tool-versions" || handle_error "ASDF global tool-versions" "Could not restore global .tool-versions"
    fi

    # Install tool versions with enhanced error handling
    if [ -f "$HOME/.tool-versions" ]; then
        log "Installing tool versions from .tool-versions..."
        echo "This may take a very long time as runtimes are compiled from source..."
        echo "You can safely interrupt and run 'asdf install' manually later if needed."

        cd "$HOME"

        # Read .tool-versions and install each tool individually
        while IFS= read -r line; do
            if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
                local tool=$(echo "$line" | awk '{print $1}')
                local version=$(echo "$line" | awk '{print $2}')

                if [ -n "$tool" ] && [ -n "$version" ]; then
                    echo "Installing $tool $version..."

                    # Check if plugin is installed first
                    if asdf plugin list | grep -q "^$tool$"; then
                        # Try to install the specific version
                        if ! asdf install "$tool" "$version"; then
                            echo "❌ Failed to install $tool $version"
                            echo "   Trying to install latest version as fallback..."

                            # Try to install latest version as fallback
                            if ! asdf install "$tool" latest; then
                                echo "❌ Failed to install latest $tool"
                                echo "   You can install it manually later with: asdf install $tool $version"
                            else
                                echo "✅ Installed latest $tool as fallback"
                            fi
                        else
                            echo "✅ Installed $tool $version"
                        fi
                    else
                        echo "⚠️  Plugin $tool not installed, skipping version installation"
                    fi
                fi
            fi
        done < "$HOME/.tool-versions"

        echo "✅ ASDF versions installation completed (check for errors above)"
    fi
}
