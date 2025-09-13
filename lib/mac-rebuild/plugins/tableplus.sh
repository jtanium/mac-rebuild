#!/bin/bash

# TablePlus Plugin for Mac Rebuild
# Handles backup and restore of TablePlus database connections, themes, and preferences

# Plugin metadata
tableplus_description() {
    echo "Manages TablePlus database connections, themes, and preferences"
}

tableplus_priority() {
    echo "45"  # After core tools, similar to other GUI applications
}

tableplus_has_detection() {
    return 0
}

tableplus_detect() {
    [[ -d "/Applications/TablePlus.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask tableplus &>/dev/null) || \
    [[ -d "$HOME/Library/Application Support/com.tinyapp.TablePlus" ]]
}

tableplus_backup() {
    log "Checking for TablePlus..."

    if ! tableplus_detect; then
        echo "TablePlus not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found TablePlus. Do you want to backup TablePlus connections and settings?" "y"; then
        echo "INCLUDE_TABLEPLUS:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/tableplus"
        mkdir -p "$backup_dir"

        # Backup TablePlus application support directory
        local tableplus_support="$HOME/Library/Application Support/com.tinyapp.TablePlus"
        if [[ -d "$tableplus_support" ]]; then
            # Backup connections (encrypted by TablePlus)
            if [[ -f "$tableplus_support/Data/Connections.plist" ]]; then
                cp "$tableplus_support/Data/Connections.plist" "$backup_dir/" 2>/dev/null || handle_error "TablePlus connections" "Could not backup connections"
            fi

            # Backup application preferences
            if [[ -f "$tableplus_support/Data/Preferences.plist" ]]; then
                cp "$tableplus_support/Data/Preferences.plist" "$backup_dir/" 2>/dev/null || handle_error "TablePlus preferences" "Could not backup preferences"
            fi

            # Backup themes
            if [[ -d "$tableplus_support/Themes" ]]; then
                cp -r "$tableplus_support/Themes" "$backup_dir/" 2>/dev/null || handle_error "TablePlus themes" "Could not backup themes"
            fi

            # Backup custom queries/snippets if they exist
            if [[ -d "$tableplus_support/Queries" ]]; then
                cp -r "$tableplus_support/Queries" "$backup_dir/" 2>/dev/null || warn "Could not backup custom queries"
            fi

            # Backup window states and layouts
            if [[ -f "$tableplus_support/Data/WindowStates.plist" ]]; then
                cp "$tableplus_support/Data/WindowStates.plist" "$backup_dir/" 2>/dev/null || warn "Could not backup window states"
            fi
        fi

        # Also backup system preferences for TablePlus
        local tableplus_prefs="$HOME/Library/Preferences/com.tinyapp.TablePlus.plist"
        if [[ -f "$tableplus_prefs" ]]; then
            cp "$tableplus_prefs" "$backup_dir/" 2>/dev/null || handle_error "TablePlus system preferences" "Could not backup system preferences"
        fi

        # Backup license information if present
        local license_file="$HOME/Library/Application Support/com.tinyapp.TablePlus/Data/License.plist"
        if [[ -f "$license_file" ]]; then
            if ask_yes_no "Backup TablePlus license information?" "y"; then
                cp "$license_file" "$backup_dir/" 2>/dev/null || warn "Could not backup license information"
                echo "✅ TablePlus license backed up"
            fi
        fi

        echo "✅ TablePlus configuration backed up"
        echo "ℹ️  Note: Database connections are encrypted by TablePlus for security"
    else
        echo "EXCLUDE_TABLEPLUS:true" >> "$USER_PREFS"
    fi
}

tableplus_restore() {
    log "Restoring TablePlus configuration..."

    local backup_dir="$BACKUP_DIR/tableplus"

    # Check if TablePlus backup exists
    if [[ ! -d "$backup_dir" ]]; then
        echo "No TablePlus backup found, skipping..."
        return 0
    fi

    # Check if user wants to restore TablePlus
    if grep -q "EXCLUDE_TABLEPLUS:true" "$USER_PREFS" 2>/dev/null; then
        echo "TablePlus restore excluded by user preference, skipping..."
        return 0
    fi

    # Install TablePlus if not present
    if ! tableplus_detect; then
        if ask_yes_no "TablePlus not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask tableplus || handle_error "TablePlus installation" "Could not install TablePlus"
                echo "✅ TablePlus installed"
            else
                warn "Homebrew not available. Please install TablePlus manually from https://tableplus.com"
                return 1
            fi
        else
            echo "Skipping TablePlus restore without TablePlus installed"
            return 0
        fi
    fi

    # Ensure TablePlus application support directory exists
    local tableplus_support="$HOME/Library/Application Support/com.tinyapp.TablePlus"
    mkdir -p "$tableplus_support/Data"

    # Restore connections
    if [[ -f "$backup_dir/Connections.plist" ]]; then
        cp "$backup_dir/Connections.plist" "$tableplus_support/Data/" 2>/dev/null || handle_error "TablePlus connections restore" "Could not restore connections"
        echo "✅ TablePlus connections restored"
    fi

    # Restore preferences
    if [[ -f "$backup_dir/Preferences.plist" ]]; then
        cp "$backup_dir/Preferences.plist" "$tableplus_support/Data/" 2>/dev/null || handle_error "TablePlus preferences restore" "Could not restore preferences"
        echo "✅ TablePlus preferences restored"
    fi

    # Restore themes
    if [[ -d "$backup_dir/Themes" ]]; then
        cp -r "$backup_dir/Themes" "$tableplus_support/" 2>/dev/null || handle_error "TablePlus themes restore" "Could not restore themes"
        echo "✅ TablePlus themes restored"
    fi

    # Restore custom queries/snippets
    if [[ -d "$backup_dir/Queries" ]]; then
        cp -r "$backup_dir/Queries" "$tableplus_support/" 2>/dev/null || warn "Could not restore custom queries"
        echo "✅ TablePlus custom queries restored"
    fi

    # Restore window states
    if [[ -f "$backup_dir/WindowStates.plist" ]]; then
        cp "$backup_dir/WindowStates.plist" "$tableplus_support/Data/" 2>/dev/null || warn "Could not restore window states"
        echo "✅ TablePlus window states restored"
    fi

    # Restore system preferences
    if [[ -f "$backup_dir/com.tinyapp.TablePlus.plist" ]]; then
        cp "$backup_dir/com.tinyapp.TablePlus.plist" "$HOME/Library/Preferences/" 2>/dev/null || handle_error "TablePlus system preferences restore" "Could not restore system preferences"
        echo "✅ TablePlus system preferences restored"
    fi

    # Restore license
    if [[ -f "$backup_dir/License.plist" ]]; then
        cp "$backup_dir/License.plist" "$tableplus_support/Data/" 2>/dev/null || warn "Could not restore license information"
        echo "✅ TablePlus license restored"
    fi

    echo "✅ TablePlus restore completed"
    echo "ℹ️  You may need to restart TablePlus for all settings to take effect"
}

tableplus_should_restore() {
    if [[ -f "$USER_PREFS" ]]; then
        grep -q "INCLUDE_TABLEPLUS:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file but backup exists
        [[ -d "$BACKUP_DIR/tableplus" ]]
    fi
}
