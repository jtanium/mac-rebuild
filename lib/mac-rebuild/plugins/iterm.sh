#!/bin/bash

# iTerm Plugin for Mac Rebuild
# Handles backup and restore of iTerm2 settings, profiles, and preferences

# Plugin metadata
iterm_description() {
    echo "Manages iTerm2 settings, profiles, color schemes, and preferences"
}

iterm_priority() {
    echo "45"  # After VS Code
}

iterm_has_detection() {
    return 0
}

iterm_detect() {
    [[ -d "/Applications/iTerm.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask iterm2 &>/dev/null)
}

iterm_backup() {
    log "Checking for iTerm2..."

    if ! iterm_detect; then
        echo "iTerm2 not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found iTerm2. Do you want to backup iTerm2 settings and profiles?" "y"; then
        echo "INCLUDE_ITERM:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/iterm"
        mkdir -p "$backup_dir"

        # Backup iTerm2 preferences
        local iterm_prefs="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
        if [[ -f "$iterm_prefs" ]]; then
            cp "$iterm_prefs" "$backup_dir/" || handle_error "iTerm preferences" "Could not copy iTerm2 preferences"
            echo "✅ iTerm2 preferences backed up"
        fi

        # Backup iTerm2 dynamic profiles
        local dynamic_profiles_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
        if [[ -d "$dynamic_profiles_dir" ]]; then
            mkdir -p "$backup_dir/DynamicProfiles"
            cp -r "$dynamic_profiles_dir/"* "$backup_dir/DynamicProfiles/" 2>/dev/null || true
            echo "✅ iTerm2 dynamic profiles backed up"
        fi

        # Backup iTerm2 scripts (if any)
        local scripts_dir="$HOME/Library/Application Support/iTerm2/Scripts"
        if [[ -d "$scripts_dir" ]]; then
            mkdir -p "$backup_dir/Scripts"
            cp -r "$scripts_dir/"* "$backup_dir/Scripts/" 2>/dev/null || true
            echo "✅ iTerm2 scripts backed up"
        fi

        # Backup color schemes
        local color_schemes_dir="$HOME/Library/Application Support/iTerm2/ColorPresets"
        if [[ -d "$color_schemes_dir" ]]; then
            mkdir -p "$backup_dir/ColorPresets"
            cp -r "$color_schemes_dir/"* "$backup_dir/ColorPresets/" 2>/dev/null || true
            echo "✅ iTerm2 color schemes backed up"
        fi

        # Export current profile as JSON (if iTerm2 is running)
        if pgrep -f "iTerm" > /dev/null; then
            echo "⚠️  iTerm2 is currently running. Profile export may not capture all settings."
            echo "   Consider closing iTerm2 and running backup again for complete settings."
        fi

        echo "✅ iTerm2 configuration backed up"
    else
        echo "EXCLUDE_ITERM:true" >> "$USER_PREFS"
    fi
}

iterm_restore() {
    # Check if iTerm2 should be restored
    if ! iterm_should_restore; then
        return 0
    fi

    log "Restoring iTerm2 configuration..."

    local backup_dir="$BACKUP_DIR/iterm"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No iTerm2 backup found, skipping..."
        return 0
    fi

    # Ensure iTerm2 is installed (it should be via Homebrew at this point)
    if ! iterm_detect; then
        echo "Installing iTerm2..."
        iterm_install_app
    else
        echo "✅ iTerm2 already installed"
    fi

    # Warn if iTerm2 is running
    if pgrep -f "iTerm" > /dev/null; then
        echo "⚠️  iTerm2 is currently running. Please close it before restoring settings."
        echo "   Settings restoration requires iTerm2 to be closed."
        if ask_yes_no "Do you want to continue anyway?" "n"; then
            echo "Continuing with restoration..."
        else
            echo "Skipping iTerm2 restoration. Run again after closing iTerm2."
            return 0
        fi
    fi

    # Create necessary directories
    mkdir -p "$HOME/Library/Application Support/iTerm2"

    # Restore preferences
    if [ -f "$backup_dir/com.googlecode.iterm2.plist" ]; then
        cp "$backup_dir/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/" || handle_error "iTerm preferences restore" "Could not restore iTerm2 preferences"
        echo "✅ iTerm2 preferences restored"
    fi

    # Restore dynamic profiles
    if [ -d "$backup_dir/DynamicProfiles" ]; then
        mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
        cp -r "$backup_dir/DynamicProfiles/"* "$HOME/Library/Application Support/iTerm2/DynamicProfiles/" 2>/dev/null || true
        echo "✅ iTerm2 dynamic profiles restored"
    fi

    # Restore scripts
    if [ -d "$backup_dir/Scripts" ]; then
        mkdir -p "$HOME/Library/Application Support/iTerm2/Scripts"
        cp -r "$backup_dir/Scripts/"* "$HOME/Library/Application Support/iTerm2/Scripts/" 2>/dev/null || true
        echo "✅ iTerm2 scripts restored"
    fi

    # Restore color schemes
    if [ -d "$backup_dir/ColorPresets" ]; then
        mkdir -p "$HOME/Library/Application Support/iTerm2/ColorPresets"
        cp -r "$backup_dir/ColorPresets/"* "$HOME/Library/Application Support/iTerm2/ColorPresets/" 2>/dev/null || true
        echo "✅ iTerm2 color schemes restored"
    fi

    # Refresh preferences cache
    defaults read com.googlecode.iterm2 > /dev/null 2>&1 || true

    echo "✅ iTerm2 configuration restored"
    echo "   Start iTerm2 to see your restored settings and profiles"
}

iterm_install_app() {
    # Check if Homebrew is available
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not available, cannot install iTerm2"
        echo "   Please install iTerm2 manually from https://iterm2.com/"
        return 1
    fi

    echo "🔧 Installing iTerm2 via Homebrew..."

    if brew install --cask iterm2; then
        echo "✅ iTerm2 successfully installed"
    else
        echo "❌ Failed to install iTerm2"
        echo "   You can try installing manually with: brew install --cask iterm2"
        echo "   Or download from: https://iterm2.com/"
        return 1
    fi
}

iterm_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_ITERM:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file
        [ -d "$BACKUP_DIR/iterm" ]
    fi
}
