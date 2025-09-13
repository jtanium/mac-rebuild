#!/bin/bash

# Brave Browser Plugin for Mac Rebuild
# Handles backup and restore of Brave bookmarks, extensions, preferences, and user data

# Plugin metadata
brave_description() {
    echo "Manages Brave Browser bookmarks, extensions, preferences, and user data"
}

brave_priority() {
    echo "51"  # After Chrome
}

brave_has_detection() {
    return 0
}

brave_detect() {
    [[ -d "/Applications/Brave Browser.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask brave-browser &>/dev/null) || \
    [[ -d "$HOME/Library/Application Support/BraveSoftware/Brave-Browser" ]]
}

brave_backup() {
    log "Checking for Brave Browser..."

    if ! brave_detect; then
        echo "Brave Browser not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Brave Browser. Do you want to backup Brave data (bookmarks, extensions, preferences)?" "y"; then
        echo "INCLUDE_BRAVE:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/brave"
        mkdir -p "$backup_dir"

        local brave_support="$HOME/Library/Application Support/BraveSoftware/Brave-Browser"

        if [[ -d "$brave_support" ]]; then
            # Backup bookmarks
            if [[ -f "$brave_support/Default/Bookmarks" ]]; then
                cp "$brave_support/Default/Bookmarks" "$backup_dir/" 2>/dev/null || handle_error "Brave bookmarks" "Could not backup bookmarks"
            fi

            # Backup preferences
            if [[ -f "$brave_support/Default/Preferences" ]]; then
                cp "$brave_support/Default/Preferences" "$backup_dir/" 2>/dev/null || handle_error "Brave preferences" "Could not backup preferences"
            fi

            # Backup Brave-specific settings (Shields, Rewards, etc.)
            if [[ -f "$brave_support/Default/Secure Preferences" ]]; then
                cp "$brave_support/Default/Secure Preferences" "$backup_dir/" 2>/dev/null || warn "Could not backup secure preferences"
            fi

            # Backup Brave Rewards data
            if [[ -d "$brave_support/Default/brave_rewards" ]]; then
                cp -r "$brave_support/Default/brave_rewards" "$backup_dir/" 2>/dev/null || warn "Could not backup Brave Rewards data"
            fi

            # Backup extension list
            if [[ -d "$brave_support/Default/Extensions" ]]; then
                find "$brave_support/Default/Extensions" -maxdepth 1 -type d -name "*" | while read -r ext_dir; do
                    if [[ -f "$ext_dir/manifest.json" ]]; then
                        echo "$(basename "$ext_dir")" >> "$backup_dir/extension_list.txt"
                    fi
                done 2>/dev/null || warn "Could not list extensions"
            fi

            # Backup login data (ask user first)
            if [[ -f "$brave_support/Default/Login Data" ]]; then
                if ask_yes_no "Backup Brave saved passwords? (Encrypted, but sensitive)" "n"; then
                    cp "$brave_support/Default/Login Data" "$backup_dir/" 2>/dev/null || warn "Could not backup login data"
                    echo "✅ Brave login data backed up (encrypted)"
                fi
            fi

            # Backup history (ask user first)
            if [[ -f "$brave_support/Default/History" ]]; then
                if ask_yes_no "Backup Brave browsing history?" "n"; then
                    cp "$brave_support/Default/History" "$backup_dir/" 2>/dev/null || warn "Could not backup history"
                    echo "✅ Brave history backed up"
                fi
            fi

            # Backup cookies (ask user first)
            if [[ -f "$brave_support/Default/Cookies" ]]; then
                if ask_yes_no "Backup Brave cookies? (May contain login sessions)" "n"; then
                    cp "$brave_support/Default/Cookies" "$backup_dir/" 2>/dev/null || warn "Could not backup cookies"
                    echo "✅ Brave cookies backed up"
                fi
            fi

            # Backup web data
            if [[ -f "$brave_support/Default/Web Data" ]]; then
                cp "$brave_support/Default/Web Data" "$backup_dir/" 2>/dev/null || warn "Could not backup web data"
            fi
        fi

        echo "✅ Brave Browser configuration backed up"
        echo "ℹ️  Note: Extensions will need to be reinstalled manually"
    else
        echo "EXCLUDE_BRAVE:true" >> "$USER_PREFS"
    fi
}

brave_restore() {
    log "Restoring Brave Browser configuration..."

    local backup_dir="$BACKUP_DIR/brave"

    if [[ ! -d "$backup_dir" ]]; then
        echo "No Brave backup found, skipping..."
        return 0
    fi

    if grep -q "EXCLUDE_BRAVE:true" "$USER_PREFS" 2>/dev/null; then
        echo "Brave restore excluded by user preference, skipping..."
        return 0
    fi

    # Install Brave if not present
    if ! brave_detect; then
        if ask_yes_no "Brave Browser not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask brave-browser || handle_error "Brave installation" "Could not install Brave Browser"
                echo "✅ Brave Browser installed"
            else
                warn "Homebrew not available. Please install Brave manually from https://brave.com"
                return 1
            fi
        else
            echo "Skipping Brave restore without Brave installed"
            return 0
        fi
    fi

    local brave_support="$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
    mkdir -p "$brave_support/Default"

    # Close Brave if running
    if pgrep -f "Brave Browser" > /dev/null; then
        if ask_yes_no "Brave is running. Close it now to restore data?" "y"; then
            pkill -f "Brave Browser" 2>/dev/null || true
            sleep 2
        else
            warn "Brave is running. Some data may not restore correctly."
        fi
    fi

    # Restore all backed up files
    for file in "Bookmarks" "Preferences" "Secure Preferences" "Login Data" "History" "Cookies" "Web Data"; do
        if [[ -f "$backup_dir/$file" ]]; then
            cp "$backup_dir/$file" "$brave_support/Default/" 2>/dev/null || warn "Could not restore $file"
            echo "✅ Brave $file restored"
        fi
    done

    # Restore Brave Rewards
    if [[ -d "$backup_dir/brave_rewards" ]]; then
        cp -r "$backup_dir/brave_rewards" "$brave_support/Default/" 2>/dev/null || warn "Could not restore Brave Rewards data"
        echo "✅ Brave Rewards data restored"
    fi

    # Show extension list
    if [[ -f "$backup_dir/extension_list.txt" ]]; then
        echo ""
        echo "ℹ️  Previously installed Brave extensions:"
        cat "$backup_dir/extension_list.txt" | while read -r ext_id; do
            echo "   - Extension ID: $ext_id"
        done
        echo "   Extensions need to be manually reinstalled"
    fi

    echo "✅ Brave Browser restore completed"
}

brave_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_BRAVE:true" "$USER_PREFS" 2>/dev/null
    else
        [[ -d "$BACKUP_DIR/brave" ]]
    fi
}
