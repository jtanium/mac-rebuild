#!/bin/bash

# Opera Browser Plugin for Mac Rebuild
# Handles backup and restore of Opera bookmarks, workspaces, preferences, and user data

# Plugin metadata
opera_description() {
    echo "Manages Opera Browser bookmarks, workspaces, preferences, and user data"
}

opera_priority() {
    echo "54"  # After Vivaldi
}

opera_has_detection() {
    return 0
}

opera_detect() {
    [[ -d "/Applications/Opera.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask opera &>/dev/null) || \
    [[ -d "$HOME/Library/Application Support/com.operasoftware.Opera" ]]
}

opera_backup() {
    log "Checking for Opera Browser..."

    if ! opera_detect; then
        echo "Opera Browser not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Opera Browser. Do you want to backup Opera data (bookmarks, workspaces, preferences)?" "y"; then
        echo "INCLUDE_OPERA:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/opera"
        mkdir -p "$backup_dir"

        local opera_support="$HOME/Library/Application Support/com.operasoftware.Opera"

        if [[ -d "$opera_support" ]]; then
            # Backup bookmarks
            if [[ -f "$opera_support/Bookmarks" ]]; then
                cp "$opera_support/Bookmarks" "$backup_dir/" 2>/dev/null || handle_error "Opera bookmarks" "Could not backup bookmarks"
            fi

            # Backup preferences (includes themes, sidebar settings)
            if [[ -f "$opera_support/Preferences" ]]; then
                cp "$opera_support/Preferences" "$backup_dir/" 2>/dev/null || handle_error "Opera preferences" "Could not backup preferences"
            fi

            # Backup Opera-specific features
            if [[ -f "$opera_support/Secure Preferences" ]]; then
                cp "$opera_support/Secure Preferences" "$backup_dir/" 2>/dev/null || warn "Could not backup secure preferences"
            fi

            # Backup workspaces (Opera's workspace feature)
            if [[ -f "$opera_support/Sessions" ]]; then
                cp "$opera_support/Sessions" "$backup_dir/" 2>/dev/null || warn "Could not backup sessions"
            fi

            # Backup Opera's sidebar configuration
            if [[ -f "$opera_support/Local State" ]]; then
                cp "$opera_support/Local State" "$backup_dir/" 2>/dev/null || warn "Could not backup local state"
            fi

            # Backup extension list
            if [[ -d "$opera_support/Extensions" ]]; then
                find "$opera_support/Extensions" -maxdepth 1 -type d -name "*" | while read -r ext_dir; do
                    if [[ -f "$ext_dir/manifest.json" ]]; then
                        echo "$(basename "$ext_dir")" >> "$backup_dir/extension_list.txt"
                    fi
                done 2>/dev/null || warn "Could not list extensions"
            fi

            # Backup Opera's built-in messengers configuration
            if [[ -d "$opera_support/Messengers" ]]; then
                cp -r "$opera_support/Messengers" "$backup_dir/" 2>/dev/null || warn "Could not backup messenger configurations"
            fi

            # Backup speed dial (Opera's start page)
            if [[ -f "$opera_support/Bookmarks.bak" ]]; then
                cp "$opera_support/Bookmarks.bak" "$backup_dir/" 2>/dev/null || warn "Could not backup speed dial backup"
            fi

            # Backup login data (ask user first)
            if [[ -f "$opera_support/Login Data" ]]; then
                if ask_yes_no "Backup Opera saved passwords? (Encrypted, but sensitive)" "n"; then
                    cp "$opera_support/Login Data" "$backup_dir/" 2>/dev/null || warn "Could not backup login data"
                    echo "✅ Opera login data backed up (encrypted)"
                fi
            fi

            # Backup history (ask user first)
            if [[ -f "$opera_support/History" ]]; then
                if ask_yes_no "Backup Opera browsing history?" "n"; then
                    cp "$opera_support/History" "$backup_dir/" 2>/dev/null || warn "Could not backup history"
                    echo "✅ Opera history backed up"
                fi
            fi

            # Backup cookies (ask user first)
            if [[ -f "$opera_support/Cookies" ]]; then
                if ask_yes_no "Backup Opera cookies? (May contain login sessions)" "n"; then
                    cp "$opera_support/Cookies" "$backup_dir/" 2>/dev/null || warn "Could not backup cookies"
                    echo "✅ Opera cookies backed up"
                fi
            fi

            # Backup web data
            if [[ -f "$opera_support/Web Data" ]]; then
                cp "$opera_support/Web Data" "$backup_dir/" 2>/dev/null || warn "Could not backup web data"
            fi
        fi

        echo "✅ Opera Browser configuration backed up"
        echo "ℹ️  Note: Opera's workspaces and sidebar messengers are included"
    else
        echo "EXCLUDE_OPERA:true" >> "$USER_PREFS"
    fi
}

opera_restore() {
    log "Restoring Opera Browser configuration..."

    local backup_dir="$BACKUP_DIR/opera"

    if [[ ! -d "$backup_dir" ]]; then
        echo "No Opera backup found, skipping..."
        return 0
    fi

    if grep -q "EXCLUDE_OPERA:true" "$USER_PREFS" 2>/dev/null; then
        echo "Opera restore excluded by user preference, skipping..."
        return 0
    fi

    # Install Opera if not present
    if ! opera_detect; then
        if ask_yes_no "Opera Browser not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask opera || handle_error "Opera installation" "Could not install Opera Browser"
                echo "✅ Opera Browser installed"
            else
                warn "Homebrew not available. Please install Opera manually from https://opera.com"
                return 1
            fi
        else
            echo "Skipping Opera restore without Opera installed"
            return 0
        fi
    fi

    local opera_support="$HOME/Library/Application Support/com.operasoftware.Opera"
    mkdir -p "$opera_support"

    # Close Opera if running
    if pgrep -f "Opera" > /dev/null; then
        if ask_yes_no "Opera is running. Close it now to restore data?" "y"; then
            pkill -f "Opera" 2>/dev/null || true
            sleep 2
        else
            warn "Opera is running. Some data may not restore correctly."
        fi
    fi

    # Restore all backed up files
    for file in "Bookmarks" "Preferences" "Secure Preferences" "Sessions" "Local State" "Login Data" "History" "Cookies" "Web Data" "Bookmarks.bak"; do
        if [[ -f "$backup_dir/$file" ]]; then
            cp "$backup_dir/$file" "$opera_support/" 2>/dev/null || warn "Could not restore $file"
            echo "✅ Opera $file restored"
        fi
    done

    # Restore messengers configuration
    if [[ -d "$backup_dir/Messengers" ]]; then
        cp -r "$backup_dir/Messengers" "$opera_support/" 2>/dev/null || warn "Could not restore messenger configurations"
        echo "✅ Opera messenger configurations restored"
    fi

    # Show extension list
    if [[ -f "$backup_dir/extension_list.txt" ]]; then
        echo ""
        echo "ℹ️  Previously installed Opera extensions:"
        cat "$backup_dir/extension_list.txt" | while read -r ext_id; do
            echo "   - Extension ID: $ext_id"
        done
        echo "   Extensions need to be manually reinstalled from Opera addons"
    fi

    echo "✅ Opera Browser restore completed"
    echo "ℹ️  Your workspaces, speed dial, and sidebar messengers should be restored"
}

opera_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_OPERA:true" "$USER_PREFS" 2>/dev/null
    else
        [[ -d "$BACKUP_DIR/opera" ]]
    fi
}
