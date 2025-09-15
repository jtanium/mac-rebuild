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
    command -v asdf &> /dev/null || [ -f "$HOME/.asdf/bin/asdf" ]
}

# New function to detect ASDF installation path
asdf_detect_installation_path() {
    # Check for Git clone installation
    if [ -f "$HOME/.asdf/asdf.sh" ] && [ -f "$HOME/.asdf/bin/asdf" ]; then
        echo "git:$HOME/.asdf/asdf.sh"
        return 0
    fi

    # Check for Homebrew installations (both Intel and Apple Silicon)
    if [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then
        echo "homebrew:/opt/homebrew/opt/asdf/libexec/asdf.sh"
        return 0
    fi

    if [ -f "/usr/local/opt/asdf/libexec/asdf.sh" ]; then
        echo "homebrew:/usr/local/opt/asdf/libexec/asdf.sh"
        return 0
    fi

    # Check if asdf command exists and try to find its path
    if command -v asdf &> /dev/null; then
        local asdf_bin=$(which asdf)
        local asdf_dir=$(dirname "$(dirname "$asdf_bin")")
        if [ -f "$asdf_dir/asdf.sh" ]; then
            echo "other:$asdf_dir/asdf.sh"
            return 0
        fi
    fi

    return 1
}

# New function to fix ASDF paths in shell configuration files
asdf_fix_shell_paths() {
    local correct_path="$1"
    local method="$2"

    log "Fixing ASDF paths in shell configuration files..."

    # List of shell configuration files to check
    local shell_files=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$HOME/.zprofile"
    )

    # Common ASDF path patterns to replace
    local old_patterns=(
        ". /opt/homebrew/opt/asdf/libexec/asdf.sh"
        ". /usr/local/opt/asdf/libexec/asdf.sh"
        ". \$HOME/.asdf/asdf.sh"
        ". ~/.asdf/asdf.sh"
        "source /opt/homebrew/opt/asdf/libexec/asdf.sh"
        "source /usr/local/opt/asdf/libexec/asdf.sh"
        "source \$HOME/.asdf/asdf.sh"
        "source ~/.asdf/asdf.sh"
        ". \$ASDF_DIR/asdf.sh"
    )

    for shell_file in "${shell_files[@]}"; do
        if [ -f "$shell_file" ]; then
            echo "Checking $shell_file..."
            local file_modified=false

            # Create a temporary file for modifications
            local temp_file=$(mktemp)
            cp "$shell_file" "$temp_file"

            # Check for and replace old ASDF patterns
            for pattern in "${old_patterns[@]}"; do
                if grep -Fq "$pattern" "$shell_file"; then
                    echo "  Found old ASDF path: $pattern"
                    # Remove the old pattern
                    sed -i.bak "/$(echo "$pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')/d" "$temp_file"
                    file_modified=true
                fi
            done

            # Also remove any ASDF_DIR exports if we're switching methods
            if [ "$method" = "homebrew" ] && grep -q "export ASDF_DIR=" "$shell_file"; then
                echo "  Removing ASDF_DIR export (not needed for Homebrew installation)"
                sed -i.bak '/export ASDF_DIR=/d' "$temp_file"
                file_modified=true
            fi

            # Add the correct configuration
            local needs_config=true
            if [ "$method" = "git" ]; then
                # Check if correct Git clone config already exists
                if grep -Fq "export ASDF_DIR=\$HOME/.asdf" "$temp_file" && grep -Fq ". \$ASDF_DIR/asdf.sh" "$temp_file"; then
                    needs_config=false
                elif grep -Fq ". ~/.asdf/asdf.sh" "$temp_file"; then
                    needs_config=false
                fi

                if [ "$needs_config" = true ]; then
                    echo "  Adding correct Git clone ASDF configuration"
                    echo "" >> "$temp_file"
                    echo "# ASDF Configuration" >> "$temp_file"
                    echo "export ASDF_DIR=\$HOME/.asdf" >> "$temp_file"
                    echo ". \$ASDF_DIR/asdf.sh" >> "$temp_file"
                    file_modified=true
                fi
            else
                # Homebrew method
                if ! grep -Fq ". $correct_path" "$temp_file"; then
                    echo "  Adding correct Homebrew ASDF configuration"
                    echo "" >> "$temp_file"
                    echo "# ASDF Configuration" >> "$temp_file"
                    echo ". $correct_path" >> "$temp_file"
                    file_modified=true
                fi
            fi

            # Apply changes if file was modified
            if [ "$file_modified" = true ]; then
                mv "$temp_file" "$shell_file"
                echo "  ✅ Updated $shell_file"
            else
                rm "$temp_file"
                echo "  ✅ $shell_file already correct"
            fi

            # Clean up backup files
            [ -f "$shell_file.bak" ] && rm "$shell_file.bak"
        fi
    done
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

    # First, detect existing ASDF installation
    local asdf_path_info
    asdf_path_info=$(asdf_detect_installation_path)

    local install_method=""
    local asdf_script_path=""

    if [ -n "$asdf_path_info" ]; then
        # ASDF is already installed, extract method and path
        install_method=$(echo "$asdf_path_info" | cut -d':' -f1)
        asdf_script_path=$(echo "$asdf_path_info" | cut -d':' -f2)
        echo "✅ ASDF already installed via $install_method method at: $asdf_script_path"

        # Fix any incorrect paths in shell configuration files
        asdf_fix_shell_paths "$asdf_script_path" "$install_method"

        # Source ASDF for current session
        if [ "$install_method" = "git" ]; then
            export ASDF_DIR="$HOME/.asdf"
            . "$HOME/.asdf/asdf.sh"
        else
            . "$asdf_script_path"
        fi

    else
        # ASDF not found, install it via Homebrew
        echo "Installing ASDF via Homebrew..."
        brew install asdf

        install_method="homebrew"
        asdf_script_path="$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh"

        # Fix shell configuration files
        asdf_fix_shell_paths "$asdf_script_path" "$install_method"

        # Source ASDF for current session
        . "$asdf_script_path"

        echo "✅ ASDF installed and configured via Homebrew"
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

        cd "$HOME" || return 1

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
