#!/bin/bash

# Modular Mac Rebuild Backup Script
# Run this script BEFORE wiping your machine to backup your current configuration

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Use environment variable if provided, otherwise fall back to default
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backup}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Load configuration and plugin system
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/plugin-system.sh"

echo "🚀 Starting modular Mac backup process..."
echo "Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create user preferences file
USER_PREFS="$BACKUP_DIR/user_preferences.txt"
echo "# User preferences for restore" > "$USER_PREFS"
echo "# Generated on $(date)" >> "$USER_PREFS"

# Function to log progress
log() {
    echo "📋 $1"
}

# Function to handle errors
handle_error() {
    echo "❌ Error in $1: $2"
    echo "Continuing with backup..."
}

# Function to ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local response

    if [[ "$default" == "y" ]]; then
        echo -n "$question [Y/n]: "
    else
        echo -n "$question [y/N]: "
    fi

    read -r response
    response=${response:-$default}
    [[ "$response" =~ ^[Yy]$ ]]
}

# Detect system information
log "Detecting system configuration..."
echo "macOS Version: $(sw_vers -productVersion)"
echo "Computer Name: $(scutil --get ComputerName)"
echo ""

# Initialize plugin system
init_plugin_system

# Check if Homebrew is installed and offer to install it
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew not installed. Installing it first would make backup more complete."
    if ask_yes_no "Would you like to install Homebrew now?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Detect Homebrew prefix for current architecture
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

# Execute pre-backup hooks
execute_plugins_by_priority "backup"

# Save list of enabled plugins
echo "# Enabled plugins during backup" > "$BACKUP_DIR/enabled_plugins.txt"
for plugin_name in "${!PLUGINS[@]}"; do
    if is_plugin_enabled "$plugin_name"; then
        echo "$plugin_name" >> "$BACKUP_DIR/enabled_plugins.txt"
    fi
done

echo ""
echo "🎉 Backup completed successfully!"
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo "📋 Summary of backed up components:"
for plugin_name in "${!PLUGINS[@]}"; do
    if is_plugin_enabled "$plugin_name"; then
        echo "  ✅ $plugin_name: $(get_plugin_description "$plugin_name")"
    fi
done

echo ""
echo "📦 Your backup is ready for transfer to your new Mac!"
echo "Copy the entire backup directory to your new system and run the restore script."
