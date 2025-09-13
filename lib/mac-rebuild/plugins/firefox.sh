#!/bin/bash

# Firefox Browser Plugin for Mac Rebuild
# Handles backup and restore of Firefox bookmarks, extensions, preferences, and user data

# Plugin metadata
firefox_description() {
    echo "Manages Firefox Browser bookmarks, extensions, preferences, and user data"
}

firefox_priority() {
    echo "55"  # After Opera
}

firefox_has_detection() {
    return 0
}

firefox_detect() {
    [[ -d "/Applications/Firefox.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask firefox &>/dev/null) || \
    [[ -d "$HOME/Library/Application Support/Firefox" ]]
}

firefox_backup() {
    log "Checking for Firefox Browser..."

    if ! firefox_detect; then
        echo "Firefox Browser not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Firefox Browser. Do you want to backup Firefox data (bookmarks, extensions, preferences)?" "y"; then
        echo "INCLUDE_FIREFOX:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/firefox"
        mkdir -p "$backup_dir"

        local firefox_support="$HOME/Library/Application Support/Firefox"

        if [[ -d "$firefox_support" ]]; then
            # Find the default profile directory
            local profiles_ini="$firefox_support/profiles.ini"
            local profile_dir=""

            if [[ -f "$profiles_ini" ]]; then
                # Extract default profile path
                profile_dir=$(grep -A5 "\[Profile0\]" "$profiles_ini" | grep "Path=" | cut -d'=' -f2 | head -1)
                if [[ -n "$profile_dir" ]]; then
                    profile_dir="$firefox_support/$profile_dir"
                fi
            fi

            # If we can't find profile, look for default pattern
            if [[ -z "$profile_dir" || ! -d "$profile_dir" ]]; then
                profile_dir=$(find "$firefox_support" -name "*.default*" -type d | head -1)
            fi

            if [[ -d "$profile_dir" ]]; then
                echo "Found Firefox profile: $(basename "$profile_dir")"

                # Backup bookmarks and places (includes history)
                if [[ -f "$profile_dir/places.sqlite" ]]; then
                    cp "$profile_dir/places.sqlite" "$backup_dir/" 2>/dev/null || handle_error "Firefox bookmarks" "Could not backup bookmarks/history"
                fi

                # Backup preferences
                if [[ -f "$profile_dir/prefs.js" ]]; then
                    cp "$profile_dir/prefs.js" "$backup_dir/" 2>/dev/null || handle_error "Firefox preferences" "Could not backup preferences"
                fi

                # Backup user.js (custom preferences)
                if [[ -f "$profile_dir/user.js" ]]; then
                    cp "$profile_dir/user.js" "$backup_dir/" 2>/dev/null || warn "Could not backup user.js"
                fi

                # Backup extensions and add-ons
                if [[ -f "$profile_dir/extensions.json" ]]; then
                    cp "$profile_dir/extensions.json" "$backup_dir/" 2>/dev/null || warn "Could not backup extensions list"
                fi

                if [[ -d "$profile_dir/extensions" ]]; then
                    cp -r "$profile_dir/extensions" "$backup_dir/" 2>/dev/null || warn "Could not backup extensions folder"
                fi

                # Backup search engines
                if [[ -f "$profile_dir/search.json.mozlz4" ]]; then
                    cp "$profile_dir/search.json.mozlz4" "$backup_dir/" 2>/dev/null || warn "Could not backup search engines"
                fi

                # Backup certificates
                if [[ -f "$profile_dir/cert9.db" ]]; then
                    cp "$profile_dir/cert9.db" "$backup_dir/" 2>/dev/null || warn "Could not backup certificates"
                fi

                # Backup cookies (ask user first)
                if [[ -f "$profile_dir/cookies.sqlite" ]]; then
                    if ask_yes_no "Backup Firefox cookies? (May contain login sessions)" "n"; then
                        cp "$profile_dir/cookies.sqlite" "$backup_dir/" 2>/dev/null || warn "Could not backup cookies"
                        echo "✅ Firefox cookies backed up"
                    fi
                fi

                # Backup form history
                if [[ -f "$profile_dir/formhistory.sqlite" ]]; then
                    if ask_yes_no "Backup Firefox form history?" "n"; then
                        cp "$profile_dir/formhistory.sqlite" "$backup_dir/" 2>/dev/null || warn "Could not backup form history"
                        echo "✅ Firefox form history backed up"
                    fi
                fi

                # Backup saved passwords (ask user first)
                if [[ -f "$profile_dir/logins.json" ]] && [[ -f "$profile_dir/key4.db" ]]; then
                    if ask_yes_no "Backup Firefox saved passwords? (Encrypted, but sensitive)" "n"; then
                        cp "$profile_dir/logins.json" "$backup_dir/" 2>/dev/null || warn "Could not backup logins.json"
                        cp "$profile_dir/key4.db" "$backup_dir/" 2>/dev/null || warn "Could not backup key4.db"
                        echo "✅ Firefox login data backed up (encrypted)"
                    fi
                fi

                # Save profile name for restoration
                echo "$(basename "$profile_dir")" > "$backup_dir/profile_name.txt"
            else
                warn "Could not locate Firefox profile directory"
            fi

            # Backup profiles.ini
            if [[ -f "$profiles_ini" ]]; then
                cp "$profiles_ini" "$backup_dir/" 2>/dev/null || warn "Could not backup profiles.ini"
            fi
        fi

        echo "✅ Firefox Browser configuration backed up"
        echo "ℹ️  Note: Firefox extensions will need to be reinstalled manually"
    else
        echo "EXCLUDE_FIREFOX:true" >> "$USER_PREFS"
    fi
}

firefox_restore() {
    log "Restoring Firefox Browser configuration..."

    local backup_dir="$BACKUP_DIR/firefox"

    if [[ ! -d "$backup_dir" ]]; then
        echo "No Firefox backup found, skipping..."
        return 0
    fi

    if grep -q "EXCLUDE_FIREFOX:true" "$USER_PREFS" 2>/dev/null; then
        echo "Firefox restore excluded by user preference, skipping..."
        return 0
    fi

    # Install Firefox if not present
    if ! firefox_detect; then
        if ask_yes_no "Firefox Browser not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask firefox || handle_error "Firefox installation" "Could not install Firefox Browser"
                echo "✅ Firefox Browser installed"
            else
                warn "Homebrew not available. Please install Firefox manually from https://firefox.com"
                return 1
            fi
        else
            echo "Skipping Firefox restore without Firefox installed"
            return 0
        fi
    fi

    local firefox_support="$HOME/Library/Application Support/Firefox"
    mkdir -p "$firefox_support"

    # Close Firefox if running
    if pgrep -f "Firefox" > /dev/null; then
        if ask_yes_no "Firefox is running. Close it now to restore data?" "y"; then
            pkill -f "Firefox" 2>/dev/null || true
            sleep 3
        else
            warn "Firefox is running. Some data may not restore correctly."
        fi
    fi

    # Restore profiles.ini first
    if [[ -f "$backup_dir/profiles.ini" ]]; then
        cp "$backup_dir/profiles.ini" "$firefox_support/" 2>/dev/null || warn "Could not restore profiles.ini"
    fi

    # Determine profile directory
    local profile_name=""
    if [[ -f "$backup_dir/profile_name.txt" ]]; then
        profile_name=$(cat "$backup_dir/profile_name.txt")
    fi

    local profile_dir=""
    if [[ -n "$profile_name" ]]; then
        profile_dir="$firefox_support/$profile_name"
        mkdir -p "$profile_dir"
    else
        # Create a default profile directory
        profile_dir="$firefox_support/default.default"
        mkdir -p "$profile_dir"
    fi

    echo "Restoring to Firefox profile: $(basename "$profile_dir")"

    # Restore all backed up files
    for file in "places.sqlite" "prefs.js" "user.js" "extensions.json" "search.json.mozlz4" "cert9.db" "cookies.sqlite" "formhistory.sqlite" "logins.json" "key4.db"; do
        if [[ -f "$backup_dir/$file" ]]; then
            cp "$backup_dir/$file" "$profile_dir/" 2>/dev/null || warn "Could not restore $file"
            echo "✅ Firefox $file restored"
        fi
    done

    # Restore extensions folder
    if [[ -d "$backup_dir/extensions" ]]; then
        cp -r "$backup_dir/extensions" "$profile_dir/" 2>/dev/null || warn "Could not restore extensions folder"
        echo "✅ Firefox extensions folder restored"
    fi

    echo "✅ Firefox Browser restore completed"
    echo "ℹ️  Start Firefox to verify all data was restored correctly"
    echo "ℹ️  Extensions may need to be reactivated in Firefox Add-ons Manager"
}

firefox_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_FIREFOX:true" "$USER_PREFS" 2>/dev/null
    else
        [[ -d "$BACKUP_DIR/firefox" ]]
    fi
}
