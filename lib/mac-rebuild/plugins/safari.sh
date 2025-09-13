#!/bin/bash

# Safari Browser Plugin for Mac Rebuild
# Handles backup and restore of Safari bookmarks, reading list, preferences, and user data

# Plugin metadata
safari_description() {
    echo "Manages Safari Browser bookmarks, reading list, preferences, and user data"
}

safari_priority() {
    echo "56"  # After Firefox
}

safari_has_detection() {
    return 0
}

safari_detect() {
    [[ -d "/Applications/Safari.app" ]] || \
    [[ -d "$HOME/Library/Safari" ]]
}

safari_backup() {
    log "Checking for Safari Browser..."

    if ! safari_detect; then
        echo "Safari Browser not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Safari Browser. Do you want to backup Safari data (bookmarks, reading list, preferences)?" "y"; then
        echo "INCLUDE_SAFARI:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/safari"
        mkdir -p "$backup_dir"

        local safari_support="$HOME/Library/Safari"

        if [[ -d "$safari_support" ]]; then
            # Backup bookmarks
            if [[ -f "$safari_support/Bookmarks.plist" ]]; then
                cp "$safari_support/Bookmarks.plist" "$backup_dir/" 2>/dev/null || handle_error "Safari bookmarks" "Could not backup bookmarks"
            fi

            # Backup reading list
            if [[ -f "$safari_support/ReadingList.plist" ]]; then
                cp "$safari_support/ReadingList.plist" "$backup_dir/" 2>/dev/null || warn "Could not backup reading list"
            fi

            # Backup top sites
            if [[ -f "$safari_support/TopSites.plist" ]]; then
                cp "$safari_support/TopSites.plist" "$backup_dir/" 2>/dev/null || warn "Could not backup top sites"
            fi

            # Backup extensions
            if [[ -d "$safari_support/Extensions" ]]; then
                # Create a list of installed extensions
                find "$safari_support/Extensions" -name "*.safariextension" -o -name "*.safariextz" | while read -r ext_path; do
                    echo "$(basename "$ext_path")" >> "$backup_dir/extension_list.txt"
                done 2>/dev/null || warn "Could not list extensions"

                # Backup extension settings
                cp -r "$safari_support/Extensions" "$backup_dir/" 2>/dev/null || warn "Could not backup extensions folder"
            fi

            # Backup Safari preferences
            if [[ -f "$HOME/Library/Preferences/com.apple.Safari.plist" ]]; then
                cp "$HOME/Library/Preferences/com.apple.Safari.plist" "$backup_dir/" 2>/dev/null || handle_error "Safari preferences" "Could not backup preferences"
            fi

            # Backup history (ask user first)
            if [[ -f "$safari_support/History.db" ]]; then
                if ask_yes_no "Backup Safari browsing history?" "n"; then
                    cp "$safari_support/History.db" "$backup_dir/" 2>/dev/null || warn "Could not backup history"
                    echo "✅ Safari history backed up"
                fi
            fi

            # Backup downloads list
            if [[ -f "$safari_support/Downloads.plist" ]]; then
                cp "$safari_support/Downloads.plist" "$backup_dir/" 2>/dev/null || warn "Could not backup downloads list"
            fi

            # Backup cookies (ask user first due to privacy)
            if [[ -f "$HOME/Library/Cookies/Cookies.binarycookies" ]]; then
                if ask_yes_no "Backup Safari cookies? (May contain login sessions)" "n"; then
                    mkdir -p "$backup_dir/Cookies"
                    cp "$HOME/Library/Cookies/Cookies.binarycookies" "$backup_dir/Cookies/" 2>/dev/null || warn "Could not backup cookies"
                    echo "✅ Safari cookies backed up"
                fi
            fi

            # Backup keychain items are handled by macOS, but note about iCloud Keychain
            echo "ℹ️  Safari passwords are stored in Keychain (backed up separately)"
        fi

        echo "✅ Safari Browser configuration backed up"
        echo "ℹ️  Note: Safari extensions from App Store will need to be re-downloaded"
    else
        echo "EXCLUDE_SAFARI:true" >> "$USER_PREFS"
    fi
}

safari_restore() {
    log "Restoring Safari Browser configuration..."

    local backup_dir="$BACKUP_DIR/safari"

    if [[ ! -d "$backup_dir" ]]; then
        echo "No Safari backup found, skipping..."
        return 0
    fi

    if grep -q "EXCLUDE_SAFARI:true" "$USER_PREFS" 2>/dev/null; then
        echo "Safari restore excluded by user preference, skipping..."
        return 0
    fi

    # Safari is built into macOS, so no installation needed
    local safari_support="$HOME/Library/Safari"
    mkdir -p "$safari_support"

    # Close Safari if running
    if pgrep -f "Safari" > /dev/null; then
        if ask_yes_no "Safari is running. Close it now to restore data?" "y"; then
            pkill -f "Safari" 2>/dev/null || true
            sleep 2
        else
            warn "Safari is running. Some data may not restore correctly."
        fi
    fi

    # Restore bookmarks and reading list
    for file in "Bookmarks.plist" "ReadingList.plist" "TopSites.plist" "Downloads.plist" "History.db"; do
        if [[ -f "$backup_dir/$file" ]]; then
            cp "$backup_dir/$file" "$safari_support/" 2>/dev/null || warn "Could not restore $file"
            echo "✅ Safari $file restored"
        fi
    done

    # Restore extensions
    if [[ -d "$backup_dir/Extensions" ]]; then
        cp -r "$backup_dir/Extensions" "$safari_support/" 2>/dev/null || warn "Could not restore extensions"
        echo "✅ Safari extensions restored"
    fi

    # Restore preferences
    if [[ -f "$backup_dir/com.apple.Safari.plist" ]]; then
        cp "$backup_dir/com.apple.Safari.plist" "$HOME/Library/Preferences/" 2>/dev/null || warn "Could not restore Safari preferences"
        echo "✅ Safari preferences restored"
    fi

    # Restore cookies
    if [[ -f "$backup_dir/Cookies/Cookies.binarycookies" ]]; then
        mkdir -p "$HOME/Library/Cookies"
        cp "$backup_dir/Cookies/Cookies.binarycookies" "$HOME/Library/Cookies/" 2>/dev/null || warn "Could not restore cookies"
        echo "✅ Safari cookies restored"
    fi

    # Show extension list
    if [[ -f "$backup_dir/extension_list.txt" ]]; then
        echo ""
        echo "ℹ️  Previously installed Safari extensions:"
        cat "$backup_dir/extension_list.txt" | while read -r ext_name; do
            echo "   - $ext_name"
        done
        echo "   App Store extensions need to be re-downloaded from App Store"
    fi

    echo "✅ Safari Browser restore completed"
    echo "ℹ️  Restart Safari to see restored bookmarks and settings"
}

safari_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_SAFARI:true" "$USER_PREFS" 2>/dev/null
    else
        [[ -d "$BACKUP_DIR/safari" ]]
    fi
}
