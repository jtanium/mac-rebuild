#!/bin/bash

# Modular Mac Rebuild Restore Script
# Run this script AFTER fresh macOS install to restore your environment

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backup}"
USER_PREFS="$BACKUP_DIR/user_preferences.txt"

# Load configuration and plugin system
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/plugin-system.sh"

echo "🚀 Starting modular Mac restore process..."
echo "Backup directory: $BACKUP_DIR"

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

# Load user preferences if available
if [ -f "$USER_PREFS" ]; then
    echo "📋 Found user preferences from backup"
    echo "   Only restoring applications you selected during backup"
else
    echo "⚠️  No user preferences found - will restore everything from backup"
fi

# Initialize plugin system
init_plugin_system

# Load enabled plugins from backup
if [ -f "$BACKUP_DIR/enabled_plugins.txt" ]; then
    log "Loading plugin configuration from backup..."
    while IFS= read -r plugin_name; do
        if [ -n "$plugin_name" ] && [[ ! "$plugin_name" =~ ^# ]]; then
            # Check if plugin exists in the loaded plugins list
            if echo "$PLUGINS_LIST" | grep -q "\b$plugin_name\b"; then
                enable_plugin "$plugin_name"
                echo "✅ Enabled plugin: $plugin_name"
            else
                echo "⚠️  Plugin $plugin_name not available in current system"
            fi
        fi
    done < "$BACKUP_DIR/enabled_plugins.txt"
else
    log "No plugin configuration found - enabling all available plugins"
    # Enable all loaded plugins by default
    for plugin_name in $(get_all_plugins); do
        enable_plugin "$plugin_name"
    done
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

# Execute restore in priority order
execute_plugins_by_priority "restore"

echo ""
echo "🎉 Restore completed successfully!"
echo ""
echo "📋 Summary of restored components:"
 for plugin_name in $(get_all_plugins); do
    if is_plugin_enabled "$plugin_name"; then
        echo "  ✅ $plugin_name: $(get_plugin_description "$plugin_name")"
    fi
done

echo ""
echo "🔄 Please restart your terminal or run 'source ~/.zshrc' to ensure all changes take effect."
echo "📱 Some applications may require manual sign-in or additional configuration."
