#!/bin/bash

# Arc Browser Plugin for Mac Rebuild
# Handles backup and restore of Arc spaces, bookmarks, preferences, and user data

# Plugin metadata
arc_description() {
    echo "Manages Arc Browser spaces, bookmarks, preferences, and user data"
}

arc_priority() {
    echo "52"  # After Brave
}

arc_has_detection() {
    return 0
}

arc_detect() {
    [[ -d "/Applications/Arc.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask arc &>/dev/null) || \
    [[ -d "$HOME/Library/Application Support/Arc" ]]
}

arc_backup() {
    log "Checking for Arc Browser..."

    if ! arc_detect; then
        echo "Arc Browser not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Arc Browser. Do you want to backup Arc data (spaces, bookmarks, preferences)?" "y"; then
        echo "INCLUDE_ARC:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/arc"
        mkdir -p "$backup_dir"

        local arc_support="$HOME/Library/Application Support/Arc"

        if [[ -d "$arc_support" ]]; then
            # Backup Arc-specific data (spaces, sidebar configuration)
            if [[ -f "$arc_support/StorableSidebar.json" ]]; then
                cp "$arc_support/StorableSidebar.json" "$backup_dir/" 2>/dev/null || handle_error "Arc sidebar" "Could not backup sidebar configuration"
            fi

            # Backup spaces configuration
            if [[ -d "$arc_support/Spaces" ]]; then
                cp -r "$arc_support/Spaces" "$backup_dir/" 2>/dev/null || handle_error "Arc spaces" "Could not backup spaces"
            fi

            # Backup user preferences
            if [[ -f "$arc_support/User Data/Default/Preferences" ]]; then
                mkdir -p "$backup_dir/User Data/Default"
                cp "$arc_support/User Data/Default/Preferences" "$backup_dir/User Data/Default/" 2>/dev/null || handle_error "Arc preferences" "Could not backup preferences"
            fi

            # Backup bookmarks (similar to Chromium structure)
            if [[ -f "$arc_support/User Data/Default/Bookmarks" ]]; then
                cp "$arc_support/User Data/Default/Bookmarks" "$backup_dir/User Data/Default/" 2>/dev/null || handle_error "Arc bookmarks" "Could not backup bookmarks"
            fi

            # Backup Arc-specific settings
            if [[ -f "$arc_support/User Data/Default/Local State" ]]; then
                cp "$arc_support/User Data/Default/Local State" "$backup_dir/User Data/Default/" 2>/dev/null || warn "Could not backup local state"
            fi

            # Backup login data (ask user first)
            if [[ -f "$arc_support/User Data/Default/Login Data" ]]; then
                if ask_yes_no "Backup Arc saved passwords? (Encrypted, but sensitive)" "n"; then
                    cp "$arc_support/User Data/Default/Login Data" "$backup_dir/User Data/Default/" 2>/dev/null || warn "Could not backup login data"
                    echo "✅ Arc login data backed up (encrypted)"
                fi
            fi

            # Backup history (ask user first)
            if [[ -f "$arc_support/User Data/Default/History" ]]; then
                if ask_yes_no "Backup Arc browsing history?" "n"; then
                    cp "$arc_support/User Data/Default/History" "$backup_dir/User Data/Default/" 2>/dev/null || warn "Could not backup history"
                    echo "✅ Arc history backed up"
                fi
            fi

            # Backup extensions if any
            if [[ -d "$arc_support/User Data/Default/Extensions" ]]; then
                find "$arc_support/User Data/Default/Extensions" -maxdepth 1 -type d -name "*" | while read -r ext_dir; do
                    if [[ -f "$ext_dir/manifest.json" ]]; then
                        echo "$(basename "$ext_dir")" >> "$backup_dir/extension_list.txt"
                    fi
                done 2>/dev/null || warn "Could not list extensions"
            fi
        fi

        echo "✅ Arc Browser configuration backed up"
        echo "ℹ️  Note: Arc's unique features like Spaces are included in the backup"
    else
        echo "EXCLUDE_ARC:true" >> "$USER_PREFS"
    fi
}

arc_restore() {
    log "Restoring Arc Browser configuration..."

    local backup_dir="$BACKUP_DIR/arc"

    if [[ ! -d "$backup_dir" ]]; then
        echo "No Arc backup found, skipping..."
        return 0
    fi

    if grep -q "EXCLUDE_ARC:true" "$USER_PREFS" 2>/dev/null; then
        echo "Arc restore excluded by user preference, skipping..."
        return 0
    fi

    # Install Arc if not present
    if ! arc_detect; then
        if ask_yes_no "Arc Browser not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask arc || handle_error "Arc installation" "Could not install Arc Browser"
                echo "✅ Arc Browser installed"
            else
                warn "Homebrew not available. Please install Arc manually from https://arc.net"
                return 1
            fi
        else
            echo "Skipping Arc restore without Arc installed"
            return 0
        fi
    fi

    local arc_support="$HOME/Library/Application Support/Arc"
    mkdir -p "$arc_support/User Data/Default"

    # Close Arc if running
    if pgrep -f "Arc" > /dev/null; then
        if ask_yes_no "Arc is running. Close it now to restore data?" "y"; then
            pkill -f "Arc" 2>/dev/null || true
            sleep 2
        else
            warn "Arc is running. Some data may not restore correctly."
        fi
    fi

    # Restore Arc-specific files
    if [[ -f "$backup_dir/StorableSidebar.json" ]]; then
        cp "$backup_dir/StorableSidebar.json" "$arc_support/" 2>/dev/null || warn "Could not restore sidebar configuration"
        echo "✅ Arc sidebar configuration restored"
    fi

    if [[ -d "$backup_dir/Spaces" ]]; then
        cp -r "$backup_dir/Spaces" "$arc_support/" 2>/dev/null || warn "Could not restore spaces"
        echo "✅ Arc spaces restored"
    fi

    # Restore standard browser data
    for file in "Preferences" "Bookmarks" "Local State" "Login Data" "History"; do
        if [[ -f "$backup_dir/User Data/Default/$file" ]]; then
            cp "$backup_dir/User Data/Default/$file" "$arc_support/User Data/Default/" 2>/dev/null || warn "Could not restore $file"
            echo "✅ Arc $file restored"
        fi
    done

    # Show extension list
    if [[ -f "$backup_dir/extension_list.txt" ]]; then
        echo ""
        echo "ℹ️  Previously installed Arc extensions:"
        cat "$backup_dir/extension_list.txt" | while read -r ext_id; do
            echo "   - Extension ID: $ext_id"
        done
        echo "   Extensions need to be manually reinstalled"
    fi

    echo "✅ Arc Browser restore completed"
    echo "ℹ️  Your Arc Spaces and sidebar configuration should be restored"
}

arc_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_ARC:true" "$USER_PREFS" 2>/dev/null
    else
        [[ -d "$BACKUP_DIR/arc" ]]
    fi
}
