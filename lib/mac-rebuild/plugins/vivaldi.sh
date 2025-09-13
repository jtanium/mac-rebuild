#!/bin/bash

# Vivaldi Browser Plugin for Mac Rebuild
# Handles backup and restore of Vivaldi bookmarks, workspaces, preferences, and user data

# Plugin metadata
vivaldi_description() {
    echo "Manages Vivaldi Browser bookmarks, workspaces, preferences, and user data"
}

vivaldi_priority() {
    echo "53"  # After Arc
}

vivaldi_has_detection() {
    return 0
}

vivaldi_detect() {
    [[ -d "/Applications/Vivaldi.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask vivaldi &>/dev/null) || \
    [[ -d "$HOME/Library/Application Support/Vivaldi" ]]
}

vivaldi_backup() {
    log "Checking for Vivaldi Browser..."

    if ! vivaldi_detect; then
        echo "Vivaldi Browser not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Vivaldi Browser. Do you want to backup Vivaldi data (bookmarks, workspaces, preferences)?" "y"; then
        echo "INCLUDE_VIVALDI:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/vivaldi"
        mkdir -p "$backup_dir"

        local vivaldi_support="$HOME/Library/Application Support/Vivaldi"

        if [[ -d "$vivaldi_support" ]]; then
            # Backup bookmarks
            if [[ -f "$vivaldi_support/Default/Bookmarks" ]]; then
                cp "$vivaldi_support/Default/Bookmarks" "$backup_dir/" 2>/dev/null || handle_error "Vivaldi bookmarks" "Could not backup bookmarks"
            fi

            # Backup preferences (includes themes, UI customizations)
            if [[ -f "$vivaldi_support/Default/Preferences" ]]; then
                cp "$vivaldi_support/Default/Preferences" "$backup_dir/" 2>/dev/null || handle_error "Vivaldi preferences" "Could not backup preferences"
            fi

            # Backup Vivaldi-specific customizations
            if [[ -f "$vivaldi_support/Default/Secure Preferences" ]]; then
                cp "$vivaldi_support/Default/Secure Preferences" "$backup_dir/" 2>/dev/null || warn "Could not backup secure preferences"
            fi

            # Backup workspaces (Vivaldi's unique feature)
            if [[ -f "$vivaldi_support/Default/Sessions" ]]; then
                cp "$vivaldi_support/Default/Sessions" "$backup_dir/" 2>/dev/null || warn "Could not backup sessions"
            fi

            # Backup custom CSS and modifications
            if [[ -d "$vivaldi_support/Default/User Data" ]]; then
                cp -r "$vivaldi_support/Default/User Data" "$backup_dir/" 2>/dev/null || warn "Could not backup user customizations"
            fi

            # Backup extension list
            if [[ -d "$vivaldi_support/Default/Extensions" ]]; then
                find "$vivaldi_support/Default/Extensions" -maxdepth 1 -type d -name "*" | while read -r ext_dir; do
                    if [[ -f "$ext_dir/manifest.json" ]]; then
                        echo "$(basename "$ext_dir")" >> "$backup_dir/extension_list.txt"
                    fi
                done 2>/dev/null || warn "Could not list extensions"
            fi

            # Backup login data (ask user first)
            if [[ -f "$vivaldi_support/Default/Login Data" ]]; then
                if ask_yes_no "Backup Vivaldi saved passwords? (Encrypted, but sensitive)" "n"; then
                    cp "$vivaldi_support/Default/Login Data" "$backup_dir/" 2>/dev/null || warn "Could not backup login data"
                    echo "✅ Vivaldi login data backed up (encrypted)"
                fi
            fi

            # Backup history (ask user first)
            if [[ -f "$vivaldi_support/Default/History" ]]; then
                if ask_yes_no "Backup Vivaldi browsing history?" "n"; then
                    cp "$vivaldi_support/Default/History" "$backup_dir/" 2>/dev/null || warn "Could not backup history"
                    echo "✅ Vivaldi history backed up"
                fi
            fi

            # Backup notes (Vivaldi's built-in notes feature)
            if [[ -f "$vivaldi_support/Default/Notes" ]]; then
                cp "$vivaldi_support/Default/Notes" "$backup_dir/" 2>/dev/null || warn "Could not backup notes"
                echo "✅ Vivaldi notes backed up"
            fi

            # Backup web data
            if [[ -f "$vivaldi_support/Default/Web Data" ]]; then
                cp "$vivaldi_support/Default/Web Data" "$backup_dir/" 2>/dev/null || warn "Could not backup web data"
            fi
        fi

        echo "✅ Vivaldi Browser configuration backed up"
        echo "ℹ️  Note: Vivaldi's workspaces and UI customizations are included"
    else
        echo "EXCLUDE_VIVALDI:true" >> "$USER_PREFS"
    fi
}

vivaldi_restore() {
    log "Restoring Vivaldi Browser configuration..."

    local backup_dir="$BACKUP_DIR/vivaldi"

    if [[ ! -d "$backup_dir" ]]; then
        echo "No Vivaldi backup found, skipping..."
        return 0
    fi

    if grep -q "EXCLUDE_VIVALDI:true" "$USER_PREFS" 2>/dev/null; then
        echo "Vivaldi restore excluded by user preference, skipping..."
        return 0
    fi

    # Install Vivaldi if not present
    if ! vivaldi_detect; then
        if ask_yes_no "Vivaldi Browser not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask vivaldi || handle_error "Vivaldi installation" "Could not install Vivaldi Browser"
                echo "✅ Vivaldi Browser installed"
            else
                warn "Homebrew not available. Please install Vivaldi manually from https://vivaldi.com"
                return 1
            fi
        else
            echo "Skipping Vivaldi restore without Vivaldi installed"
            return 0
        fi
    fi

    local vivaldi_support="$HOME/Library/Application Support/Vivaldi"
    mkdir -p "$vivaldi_support/Default"

    # Close Vivaldi if running
    if pgrep -f "Vivaldi" > /dev/null; then
        if ask_yes_no "Vivaldi is running. Close it now to restore data?" "y"; then
            pkill -f "Vivaldi" 2>/dev/null || true
            sleep 2
        else
            warn "Vivaldi is running. Some data may not restore correctly."
        fi
    fi

    # Restore all backed up files
    for file in "Bookmarks" "Preferences" "Secure Preferences" "Sessions" "Login Data" "History" "Notes" "Web Data"; do
        if [[ -f "$backup_dir/$file" ]]; then
            cp "$backup_dir/$file" "$vivaldi_support/Default/" 2>/dev/null || warn "Could not restore $file"
            echo "✅ Vivaldi $file restored"
        fi
    done

    # Restore user customizations
    if [[ -d "$backup_dir/User Data" ]]; then
        cp -r "$backup_dir/User Data" "$vivaldi_support/Default/" 2>/dev/null || warn "Could not restore user customizations"
        echo "✅ Vivaldi user customizations restored"
    fi

    # Show extension list
    if [[ -f "$backup_dir/extension_list.txt" ]]; then
        echo ""
        echo "ℹ️  Previously installed Vivaldi extensions:"
        cat "$backup_dir/extension_list.txt" | while read -r ext_id; do
            echo "   - Extension ID: $ext_id"
        done
        echo "   Extensions need to be manually reinstalled"
    fi

    echo "✅ Vivaldi Browser restore completed"
    echo "ℹ️  Your workspaces, notes, and UI customizations should be restored"
}

vivaldi_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_VIVALDI:true" "$USER_PREFS" 2>/dev/null
    else
        [[ -d "$BACKUP_DIR/vivaldi" ]]
    fi
}
