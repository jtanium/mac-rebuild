#!/bin/bash

# Interactive Mac Rebuild Restore Script
# Run this script AFTER fresh macOS install to restore your environment

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backup}"
USER_PREFS="$BACKUP_DIR/user_preferences.txt"

# Detect Homebrew installation path
if [[ $(uname -m) == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

echo "🚀 Starting interactive Mac restore process..."
echo "Backup directory: $BACKUP_DIR"
echo "Detected Homebrew prefix: $HOMEBREW_PREFIX"

# Check if backup exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found: $BACKUP_DIR"
    echo "Make sure you've copied your backup to this location first!"
    exit 1
fi

# Function to log progress
log() {
    echo "📋 $1"
}

# Function to handle errors
handle_error() {
    echo "❌ Error in $1: $2"
    echo "Continuing with restore..."
}

# Function to check user preference
should_include() {
    local key="$1"
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_${key}:true" "$USER_PREFS" 2>/dev/null
    else
        # Default behavior if no preferences file
        return 0
    fi
}

# Function to check if user excluded something
is_excluded() {
    local key="$1"
    if [ -f "$USER_PREFS" ]; then
        grep -q "EXCLUDE_${key}:true" "$USER_PREFS" 2>/dev/null
    else
        return 1
    fi
}

# Load user preferences if available
if [ -f "$USER_PREFS" ]; then
    echo "📋 Found user preferences from backup"
    echo "   Only restoring applications you selected during backup"
else
    echo "⚠️  No user preferences found - will restore everything from backup"
fi

# Install Xcode Command Line Tools first
log "Installing Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools (this may take a while)..."
    xcode-select --install
    echo "⏳ Please complete the Xcode Command Line Tools installation and press Enter to continue..."
    read -p ""
else
    echo "✅ Xcode Command Line Tools already installed"
fi

# Install Homebrew
log "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    echo "eval \"\$(${HOMEBREW_PREFIX}/bin/brew shellenv)\"" >> ~/.zprofile
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
    echo "✅ Homebrew installed"
else
    echo "✅ Homebrew already installed"
fi

# Install mas (Mac App Store CLI) first
log "Installing mas (Mac App Store CLI)..."
brew install mas || handle_error "mas installation" "Could not install mas"

# Restore Homebrew taps
log "Restoring Homebrew taps..."
if [ -f "$BACKUP_DIR/homebrew/taps.txt" ]; then
    while IFS= read -r tap; do
        if [ -n "$tap" ]; then
            brew tap "$tap" || handle_error "Homebrew tap" "Could not add tap: $tap"
        fi
    done < "$BACKUP_DIR/homebrew/taps.txt"
    echo "✅ Homebrew taps restored"
fi

# Restore Homebrew formulas (intelligently)
log "Restoring Homebrew formulas..."
if [ -f "$BACKUP_DIR/homebrew/formulas.txt" ]; then
    while IFS= read -r formula; do
        if [ -n "$formula" ]; then
            # Check if this is an optional formula that user excluded
            if [ -f "$USER_PREFS" ] && grep -q "EXCLUDE_FORMULA:$formula" "$USER_PREFS" 2>/dev/null; then
                echo "⏭️  Skipping $formula (excluded by user)"
                continue
            fi

            brew install "$formula" || handle_error "Homebrew formula" "Could not install: $formula"
        fi
    done < "$BACKUP_DIR/homebrew/formulas.txt"
    echo "✅ Homebrew formulas restored"
fi

# Restore Homebrew casks (intelligently)
log "Restoring Homebrew casks..."
if [ -f "$BACKUP_DIR/homebrew/casks.txt" ]; then
    while IFS= read -r cask; do
        if [ -n "$cask" ]; then
            # Check if this is an optional cask that user excluded
            if [ -f "$USER_PREFS" ] && grep -q "EXCLUDE_CASK:$cask" "$USER_PREFS" 2>/dev/null; then
                echo "⏭️  Skipping $cask (excluded by user)"
                continue
            fi

            brew install --cask "$cask" || handle_error "Homebrew cask" "Could not install: $cask"
        fi
    done < "$BACKUP_DIR/homebrew/casks.txt"
    echo "✅ Homebrew casks restored"
fi

# Install ASDF if it was backed up
log "Installing and configuring ASDF..."
if [ -f "$BACKUP_DIR/asdf/plugins.txt" ]; then
    # Install ASDF via Homebrew if not already installed
    if ! command -v asdf &> /dev/null; then
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

    # Install system dependencies for common ASDF plugins
    log "Installing system dependencies for ASDF plugins..."
    echo "This may take a while as we install compilation dependencies..."

    # Check what plugins we're about to install and install their dependencies
    if [ -f "$BACKUP_DIR/asdf/plugins.txt" ]; then
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
        done < "$BACKUP_DIR/asdf/plugins.txt"
    fi

    # Restore ASDF plugins with proper error handling
    log "Restoring ASDF plugins..."
    failed_plugins=()

    # Use plugin URLs if available, otherwise fall back to plugin names
    if [ -f "$BACKUP_DIR/asdf/plugin_urls.txt" ]; then
        while IFS= read -r line; do
            if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
                plugin_name=$(echo "$line" | awk '{print $1}')
                plugin_url=$(echo "$line" | awk '{print $2}')

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
        done < "$BACKUP_DIR/asdf/plugin_urls.txt"
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
        done < "$BACKUP_DIR/asdf/plugins.txt"
    fi

    # Report failed plugins
    if [ ${#failed_plugins[@]} -gt 0 ]; then
        echo "⚠️  The following plugins failed to install:"
        printf '   - %s\n' "${failed_plugins[@]}"
        echo "   You may need to install them manually later."
    fi

    # Restore .tool-versions files
    if [ -f "$BACKUP_DIR/asdf/.tool-versions" ]; then
        echo "Restoring .tool-versions file..."
        cp "$BACKUP_DIR/asdf/.tool-versions" "$HOME/" || handle_error "ASDF tool-versions" "Could not restore .tool-versions"
    fi

    if [ -f "$BACKUP_DIR/asdf/.tool-versions-global" ]; then
        echo "Restoring global .tool-versions file..."
        mkdir -p "$HOME/.asdf"
        cp "$BACKUP_DIR/asdf/.tool-versions-global" "$HOME/.asdf/.tool-versions" || handle_error "ASDF global tool-versions" "Could not restore global .tool-versions"
    fi

    # Install tool versions from .tool-versions with better error handling
    if [ -f "$HOME/.tool-versions" ]; then
        log "Installing tool versions from .tool-versions..."
        echo "This may take a very long time as runtimes are compiled from source..."
        echo "You can safely interrupt and run 'asdf install' manually later if needed."

        cd "$HOME"

        # Read .tool-versions and install each tool individually with better error handling
        while IFS= read -r line; do
            if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
                tool=$(echo "$line" | awk '{print $1}')
                version=$(echo "$line" | awk '{print $2}')

                if [ -n "$tool" ] && [ -n "$version" ]; then
                    echo "Installing $tool $version..."

                    # Check if plugin is installed first
                    if asdf plugin list | grep -q "^$tool$"; then
                        # Try to install the specific version
                        if ! asdf install "$tool" "$version"; then
                            echo "❌ Failed to install $tool $version"
                            echo "   You can install it manually later with: asdf install $tool $version"

                            # Try to install latest available version as fallback
                            echo "   Attempting to install latest version of $tool..."
                            latest_version=$(asdf latest "$tool" 2>/dev/null || echo "")
                            if [ -n "$latest_version" ] && [ "$latest_version" != "$version" ]; then
                                if asdf install "$tool" "$latest_version" 2>/dev/null; then
                                    echo "✅ Installed $tool $latest_version (latest) instead"
                                    asdf global "$tool" "$latest_version" 2>/dev/null || true
                                else
                                    echo "❌ Could not install any version of $tool"
                                fi
                            fi
                        else
                            echo "✅ Successfully installed $tool $version"
                            asdf global "$tool" "$version" 2>/dev/null || true
                        fi
                    else
                        echo "⚠️  Plugin $tool not available, skipping..."
                    fi
                fi
            fi
        done < "$HOME/.tool-versions"
    fi

    # Final reshim to ensure all binaries are available
    echo "Reshimming ASDF..."
    asdf reshim 2>/dev/null || true

    echo "✅ ASDF configuration restored"
    echo ""
    echo "📋 ASDF Restoration Summary:"
    echo "   - Plugins restored with dependency management"
    echo "   - Tool versions installed (some may have failed)"
    echo "   - Run 'asdf current' to see active versions"
    echo "   - Run 'asdf install' to retry any failed installations"

    if [ ${#failed_plugins[@]} -gt 0 ]; then
        echo "   - Some plugins failed - you may need to install them manually"
    fi
fi

# Restore App Store apps
log "Restoring App Store applications..."
if [ -f "$BACKUP_DIR/apps/app_store_apps.txt" ]; then
    echo "⚠️  App Store apps need to be signed in first. Please sign into the Mac App Store and press Enter to continue..."
    read -p ""

    while IFS= read -r line; do
        if [ -n "$line" ]; then
            # Extract app ID (first field before space)
            app_id=$(echo "$line" | awk '{print $1}')
            if [[ "$app_id" =~ ^[0-9]+$ ]]; then
                mas install "$app_id" || handle_error "App Store app" "Could not install app ID: $app_id"
            fi
        fi
    done < "$BACKUP_DIR/apps/app_store_apps.txt"
    echo "✅ App Store applications restored"
fi

# Restore dotfiles
log "Restoring dotfiles and configurations..."
if [ -d "$BACKUP_DIR/dotfiles" ]; then
    # Create .ssh directory with proper permissions
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Copy dotfiles
    find "$BACKUP_DIR/dotfiles" -type f | while read -r file; do
        relative_path="${file#$BACKUP_DIR/dotfiles/}"
        target_path="$HOME/$relative_path"
        target_dir=$(dirname "$target_path")

        mkdir -p "$target_dir"
        cp "$file" "$target_path" || handle_error "Dotfile restore" "Could not restore: $relative_path"

        # Set proper permissions for SSH files
        if [[ "$relative_path" == .ssh/* ]]; then
            if [[ "$relative_path" == *.pub ]]; then
                chmod 644 "$target_path"
            else
                chmod 600 "$target_path"
            fi
        fi
    done
    echo "✅ Dotfiles restored"
fi

# Restore SSH keys (only if user included them)
if should_include "SSH" && [ -d "$BACKUP_DIR/ssh_keys/.ssh" ]; then
    log "Restoring SSH keys..."
    cp -r "$BACKUP_DIR/ssh_keys/.ssh/"* "$HOME/.ssh/" 2>/dev/null || handle_error "SSH keys" "Could not restore SSH keys"
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/"* 2>/dev/null || true
    chmod 644 "$HOME/.ssh/"*.pub 2>/dev/null || true
    echo "✅ SSH keys restored"
elif is_excluded "SSH"; then
    echo "⏭️  Skipping SSH keys (excluded by user)"
fi

# Restore VS Code configuration (only if user included it)
if should_include "VSCODE" && [ -d "$BACKUP_DIR/vscode" ]; then
    log "Restoring VS Code configuration..."
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    mkdir -p "$VSCODE_USER_DIR"

    if [ -f "$BACKUP_DIR/vscode/settings.json" ]; then
        cp "$BACKUP_DIR/vscode/settings.json" "$VSCODE_USER_DIR/" || handle_error "VS Code settings" "Could not restore settings.json"
    fi

    if [ -f "$BACKUP_DIR/vscode/keybindings.json" ]; then
        cp "$BACKUP_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/" || handle_error "VS Code keybindings" "Could not restore keybindings.json"
    fi

    if [ -f "$BACKUP_DIR/vscode/extensions.txt" ] && command -v code &> /dev/null; then
        while IFS= read -r extension; do
            if [ -n "$extension" ]; then
                code --install-extension "$extension" || handle_error "VS Code extension" "Could not install: $extension"
            fi
        done < "$BACKUP_DIR/vscode/extensions.txt"
    fi
    echo "✅ VS Code configuration restored"
elif is_excluded "VSCODE"; then
    echo "⏭️  Skipping VS Code configuration (excluded by user)"
fi

# Restore JetBrains IDE configurations (only if user included it)
if should_include "JETBRAINS" && [ -d "$BACKUP_DIR/jetbrains" ]; then
    log "Restoring JetBrains IDE configurations..."
    for ide_backup in "$BACKUP_DIR/jetbrains"/*; do
        if [ -d "$ide_backup" ]; then
            ide_name=$(basename "$ide_backup")
            target_dir="$HOME/Library/Application Support/JetBrains/$ide_name"

            if [ -d "$target_dir" ]; then
                # Restore configuration directories
                for config_dir in options keymaps colors; do
                    if [ -d "$ide_backup/$config_dir" ]; then
                        cp -r "$ide_backup/$config_dir" "$target_dir/" || handle_error "JetBrains $ide_name" "Could not restore $config_dir"
                    fi
                done
            fi
        fi
    done
    echo "✅ JetBrains IDE configurations restored"
elif is_excluded "JETBRAINS"; then
    echo "⏭️  Skipping JetBrains configurations (excluded by user)"
fi

# Final setup steps
log "Performing final setup steps..."

# Source shell configuration
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null || true
fi

# Create restore summary
cat > "$SCRIPT_DIR/restore_summary.txt" << EOF
Interactive Mac Restore Summary
===============================
Restore Date: $(date)
macOS Version: $(sw_vers -productVersion)
Computer Name: $(scutil --get ComputerName)

Restored Components:
- ✅ Homebrew and packages (with user preferences)
- ✅ ASDF version manager and tools
- ✅ App Store applications
- ✅ Dotfiles and configurations
EOF

if should_include "SSH"; then
    echo "- ✅ SSH keys" >> "$SCRIPT_DIR/restore_summary.txt"
fi

if should_include "VSCODE"; then
    echo "- ✅ VS Code settings and extensions" >> "$SCRIPT_DIR/restore_summary.txt"
fi

if should_include "JETBRAINS"; then
    echo "- ✅ JetBrains IDE configurations" >> "$SCRIPT_DIR/restore_summary.txt"
fi

cat >> "$SCRIPT_DIR/restore_summary.txt" << EOF

Manual Steps Remaining:
1. Sign into cloud services (iCloud, Google, etc.)
2. Configure system preferences to your liking
3. Set up any proprietary software licenses
4. Configure any custom application settings
5. Verify all applications are working correctly

Backup Location: $BACKUP_DIR
User Preferences: $USER_PREFS
EOF

echo ""
echo "🎉 Restore completed successfully!"
echo "📄 Summary: $SCRIPT_DIR/restore_summary.txt"
echo ""
echo "🔧 Manual steps remaining:"
echo "   1. Sign into cloud services (iCloud, Google Drive, etc.)"
echo "   2. Configure System Preferences to your liking"
echo "   3. Set up any proprietary software licenses"
echo "   4. Open and configure each application"
echo "   5. Verify everything is working correctly"
echo ""
echo "💡 Consider running: brew doctor && brew cleanup"
