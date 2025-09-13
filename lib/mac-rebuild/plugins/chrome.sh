#!/bin/bash

# Google Chrome Plugin for Mac Rebuild
# Handles backup and restore of Chrome bookmarks, extensions, preferences, and user data

# Plugin metadata
chrome_description() {
    echo "Manages Google Chrome bookmarks, extensions, preferences, and user data"
}

chrome_priority() {
    echo "50"  # After core development tools
}

chrome_has_detection() {
    return 0
}

chrome_detect() {
    [[ -d "/Applications/Google Chrome.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask google-chrome &>/dev/null) || \
    [[ -d "$HOME/Library/Application Support/Google/Chrome" ]]
}

chrome_backup() {
    log "Checking for Google Chrome..."

    if ! chrome_detect; then
        echo "Google Chrome not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Google Chrome. Do you want to backup Chrome data (bookmarks, extensions, preferences)?" "y"; then
        echo "INCLUDE_CHROME:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/chrome"
        mkdir -p "$backup_dir"

        local chrome_support="$HOME/Library/Application Support/Google/Chrome"

        if [[ -d "$chrome_support" ]]; then
            # Backup bookmarks
            if [[ -f "$chrome_support/Default/Bookmarks" ]]; then
                cp "$chrome_support/Default/Bookmarks" "$backup_dir/" 2>/dev/null || handle_error "Chrome bookmarks" "Could not backup bookmarks"
            fi

            # Backup preferences
            if [[ -f "$chrome_support/Default/Preferences" ]]; then
                cp "$chrome_support/Default/Preferences" "$backup_dir/" 2>/dev/null || handle_error "Chrome preferences" "Could not backup preferences"
            fi

            # Backup extensions (state and preferences)
            if [[ -d "$chrome_support/Default/Extensions" ]]; then
                # Create a list of installed extensions
                find "$chrome_support/Default/Extensions" -maxdepth 1 -type d -name "*" | while read -r ext_dir; do
                    if [[ -f "$ext_dir/manifest.json" ]]; then
                        echo "$(basename "$ext_dir")" >> "$backup_dir/extension_list.txt"
                    fi
                done 2>/dev/null || warn "Could not list extensions"
            fi

            # Backup extension preferences
            if [[ -f "$chrome_support/Default/Secure Preferences" ]]; then
                cp "$chrome_support/Default/Secure Preferences" "$backup_dir/" 2>/dev/null || warn "Could not backup secure preferences"
            fi

            # Backup login data (ask user first due to sensitivity)
            if [[ -f "$chrome_support/Default/Login Data" ]]; then
                if ask_yes_no "Backup Chrome saved passwords? (Encrypted, but sensitive)" "n"; then
                    cp "$chrome_support/Default/Login Data" "$backup_dir/" 2>/dev/null || warn "Could not backup login data"
                    echo "✅ Chrome login data backed up (encrypted)"
                fi
            fi

            # Backup history (ask user first due to privacy)
            if [[ -f "$chrome_support/Default/History" ]]; then
                if ask_yes_no "Backup Chrome browsing history?" "n"; then
                    cp "$chrome_support/Default/History" "$backup_dir/" 2>/dev/null || warn "Could not backup history"
                    echo "✅ Chrome history backed up"
                fi
            fi

            # Backup cookies (ask user first due to privacy)
            if [[ -f "$chrome_support/Default/Cookies" ]]; then
                if ask_yes_no "Backup Chrome cookies? (May contain login sessions)" "n"; then
                    cp "$chrome_support/Default/Cookies" "$backup_dir/" 2>/dev/null || warn "Could not backup cookies"
                    echo "✅ Chrome cookies backed up"
                fi
            fi

            # Backup shortcuts and web app data
            if [[ -f "$chrome_support/Default/Web Data" ]]; then
                cp "$chrome_support/Default/Web Data" "$backup_dir/" 2>/dev/null || warn "Could not backup web data"
            fi

            # Backup user scripts and custom CSS if present
            if [[ -d "$chrome_support/Default/User StyleSheets" ]]; then
                cp -r "$chrome_support/Default/User StyleSheets" "$backup_dir/" 2>/dev/null || warn "Could not backup user stylesheets"
            fi
        fi

        echo "✅ Chrome configuration backed up"
        echo "ℹ️  Note: Extensions will need to be reinstalled manually from Chrome Web Store"
    else
        echo "EXCLUDE_CHROME:true" >> "$USER_PREFS"
    fi
}

chrome_restore() {
    log "Restoring Google Chrome configuration..."

    local backup_dir="$BACKUP_DIR/chrome"

    # Check if Chrome backup exists
    if [[ ! -d "$backup_dir" ]]; then
        echo "No Chrome backup found, skipping..."
        return 0
    fi

    # Check if user wants to restore Chrome
    if grep -q "EXCLUDE_CHROME:true" "$USER_PREFS" 2>/dev/null; then
        echo "Chrome restore excluded by user preference, skipping..."
        return 0
    fi

    # Install Chrome if not present
    if ! chrome_detect; then
        if ask_yes_no "Google Chrome not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask google-chrome || handle_error "Chrome installation" "Could not install Google Chrome"
                echo "✅ Google Chrome installed"
            else
                warn "Homebrew not available. Please install Chrome manually from https://google.com/chrome"
                return 1
            fi
        else
            echo "Skipping Chrome restore without Chrome installed"
            return 0
        fi
    fi

    # Ensure Chrome application support directory exists
    local chrome_support="$HOME/Library/Application Support/Google/Chrome"
    mkdir -p "$chrome_support/Default"

    # Chrome needs to be closed for file restoration
    if pgrep -f "Google Chrome" > /dev/null; then
        if ask_yes_no "Chrome is running. Close it now to restore data?" "y"; then
            pkill -f "Google Chrome" 2>/dev/null || true
            sleep 2
        else
            warn "Chrome is running. Some data may not restore correctly."
        fi
    fi

    # Restore bookmarks
    if [[ -f "$backup_dir/Bookmarks" ]]; then
        cp "$backup_dir/Bookmarks" "$chrome_support/Default/" 2>/dev/null || handle_error "Chrome bookmarks restore" "Could not restore bookmarks"
        echo "✅ Chrome bookmarks restored"
    fi

    # Restore preferences
    if [[ -f "$backup_dir/Preferences" ]]; then
        cp "$backup_dir/Preferences" "$chrome_support/Default/" 2>/dev/null || handle_error "Chrome preferences restore" "Could not restore preferences"
        echo "✅ Chrome preferences restored"
    fi

    # Restore secure preferences
    if [[ -f "$backup_dir/Secure Preferences" ]]; then
        cp "$backup_dir/Secure Preferences" "$chrome_support/Default/" 2>/dev/null || warn "Could not restore secure preferences"
        echo "✅ Chrome secure preferences restored"
    fi

    # Restore login data
    if [[ -f "$backup_dir/Login Data" ]]; then
        cp "$backup_dir/Login Data" "$chrome_support/Default/" 2>/dev/null || warn "Could not restore login data"
        echo "✅ Chrome login data restored"
    fi

    # Restore history
    if [[ -f "$backup_dir/History" ]]; then
        cp "$backup_dir/History" "$chrome_support/Default/" 2>/dev/null || warn "Could not restore history"
        echo "✅ Chrome history restored"
    fi

    # Restore cookies
    if [[ -f "$backup_dir/Cookies" ]]; then
        cp "$backup_dir/Cookies" "$chrome_support/Default/" 2>/dev/null || warn "Could not restore cookies"
        echo "✅ Chrome cookies restored"
    fi

    # Restore web data
    if [[ -f "$backup_dir/Web Data" ]]; then
        cp "$backup_dir/Web Data" "$chrome_support/Default/" 2>/dev/null || warn "Could not restore web data"
        echo "✅ Chrome web data restored"
    fi

    # Restore user stylesheets
    if [[ -d "$backup_dir/User StyleSheets" ]]; then
        cp -r "$backup_dir/User StyleSheets" "$chrome_support/Default/" 2>/dev/null || warn "Could not restore user stylesheets"
        echo "✅ Chrome user stylesheets restored"
    fi

    # Show extension list if available
    if [[ -f "$backup_dir/extension_list.txt" ]]; then
        echo ""
        echo "ℹ️  Previously installed Chrome extensions:"
        cat "$backup_dir/extension_list.txt" | while read -r ext_id; do
            echo "   - Extension ID: $ext_id"
        done
        echo "   Extensions need to be manually reinstalled from Chrome Web Store"
    fi

    echo "✅ Chrome restore completed"
    echo "ℹ️  Start Chrome to verify all data was restored correctly"
}

chrome_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_CHROME:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file but backup exists
        [[ -d "$BACKUP_DIR/chrome" ]]
    fi
}
