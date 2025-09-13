#!/bin/bash

# 1Password Plugin for Mac Rebuild
# Handles backup and restore of 1Password settings and data

# Plugin metadata
1password_description() {
    echo "Manages 1Password app settings and preferences"
}

1password_priority() {
    echo "30"  # After core tools
}

1password_has_detection() {
    return 0
}

1password_detect() {
    [[ -d "/Applications/1Password 7 - Password Manager.app" ]] || \
    [[ -d "/Applications/1Password.app" ]] || \
    (command -v brew &> /dev/null && brew list 1password &>/dev/null)
}

1password_backup() {
    log "Checking for 1Password..."

    if ! 1password_detect; then
        echo "1Password not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found 1Password. Do you want to backup 1Password settings?" "y"; then
        echo "INCLUDE_1PASSWORD:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/1password"
        mkdir -p "$backup_dir"

        # Backup 1Password settings
        if [[ -d "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password" ]]; then
            cp -R "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/" "$backup_dir/group_containers/" 2>/dev/null || handle_error "1Password group containers" "Could not backup group containers"
        fi

        if [[ -d "$HOME/Library/Containers/com.1password.1password" ]]; then
            cp -R "$HOME/Library/Containers/com.1password.1password/" "$backup_dir/containers/" 2>/dev/null || handle_error "1Password containers" "Could not backup containers"
        fi

        # Backup preferences
        if [[ -f "$HOME/Library/Preferences/com.1password.1password.plist" ]]; then
            cp "$HOME/Library/Preferences/com.1password.1password.plist" "$backup_dir/" 2>/dev/null || handle_error "1Password preferences" "Could not backup preferences"
        fi

        echo "✅ 1Password configuration backed up"
        echo "⚠️  Note: Vault data is not backed up for security reasons"
    else
        echo "EXCLUDE_1PASSWORD:true" >> "$USER_PREFS"
    fi
}

1password_restore() {
    # Check if 1Password should be restored
    if ! 1password_should_restore; then
        return 0
    fi

    log "Restoring 1Password configuration..."

    local backup_dir="$BACKUP_DIR/1password"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No 1Password backup found, skipping..."
        return 0
    fi

    # Ensure 1Password is installed (install if missing)
    if ! 1password_detect; then
        if ask_yes_no "1Password not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask 1password || handle_error "1Password installation" "Could not install 1Password"
                echo "✅ 1Password installed"
            else
                echo "❌ Homebrew not available. Please install 1Password manually from https://1password.com/"
                return 1
            fi
        else
            echo "Skipping 1Password restore without 1Password installed"
            return 0
        fi
    fi

    # Restore group containers
    if [[ -d "$backup_dir/group_containers" ]]; then
        mkdir -p "$HOME/Library/Group Containers/"
        cp -R "$backup_dir/group_containers/" "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/" 2>/dev/null || handle_error "1Password group containers restore" "Could not restore group containers"
    fi

    # Restore containers
    if [[ -d "$backup_dir/containers" ]]; then
        mkdir -p "$HOME/Library/Containers/"
        cp -R "$backup_dir/containers/" "$HOME/Library/Containers/com.1password.1password/" 2>/dev/null || handle_error "1Password containers restore" "Could not restore containers"
    fi

    # Restore preferences
    if [[ -f "$backup_dir/com.1password.1password.plist" ]]; then
        cp "$backup_dir/com.1password.1password.plist" "$HOME/Library/Preferences/" || handle_error "1Password preferences restore" "Could not restore preferences"
    fi

    echo "✅ 1Password configuration restored"
    echo "⚠️  You may need to sign in to your 1Password account"
}

1password_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_1PASSWORD:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file
        [ -d "$BACKUP_DIR/1password" ]
    fi
}
