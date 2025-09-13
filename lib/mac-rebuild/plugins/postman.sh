#!/bin/bash

# Postman Plugin for Mac Rebuild
# Handles backup and restore of Postman settings, collections, and environments

# Plugin metadata
postman_description() {
    echo "Manages Postman API testing tool settings, collections, and environments"
}

postman_priority() {
    echo "35"  # After core tools
}

postman_has_detection() {
    return 0
}

postman_detect() {
    [[ -d "/Applications/Postman.app" ]] || \
    (command -v brew &> /dev/null && brew list postman &>/dev/null)
}

postman_backup() {
    log "Checking for Postman..."

    if ! postman_detect; then
        echo "Postman not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Postman. Do you want to backup Postman settings and collections?" "y"; then
        echo "INCLUDE_POSTMAN:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/postman"
        mkdir -p "$backup_dir"

        # Backup Postman settings and data
        if [[ -d "$HOME/Library/Application Support/Postman" ]]; then
            cp -R "$HOME/Library/Application Support/Postman/" "$backup_dir/application_support/" 2>/dev/null || handle_error "Postman application support" "Could not backup application support"
        fi

        # Backup preferences
        if [[ -f "$HOME/Library/Preferences/com.postmanlabs.mac.plist" ]]; then
            cp "$HOME/Library/Preferences/com.postmanlabs.mac.plist" "$backup_dir/" 2>/dev/null || handle_error "Postman preferences" "Could not backup preferences"
        fi

        # Backup Postman collections (if stored locally)
        if [[ -d "$HOME/Postman" ]]; then
            cp -R "$HOME/Postman/" "$backup_dir/collections/" 2>/dev/null || handle_error "Postman collections" "Could not backup collections"
        fi

        echo "✅ Postman configuration backed up"
        echo "⚠️  Note: Cloud-synced collections are not backed up locally"
    else
        echo "EXCLUDE_POSTMAN:true" >> "$USER_PREFS"
    fi
}

postman_restore() {
    # Check if Postman should be restored
    if ! postman_should_restore; then
        return 0
    fi

    log "Restoring Postman configuration..."

    local backup_dir="$BACKUP_DIR/postman"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No Postman backup found, skipping..."
        return 0
    fi

    # Ensure Postman is installed
    if ! postman_detect; then
        echo "⚠️  Postman not installed, skipping configuration restore..."
        return 0
    fi

    # Restore application support
    if [[ -d "$backup_dir/application_support" ]]; then
        mkdir -p "$HOME/Library/Application Support/"
        cp -R "$backup_dir/application_support/" "$HOME/Library/Application Support/Postman/" 2>/dev/null || handle_error "Postman application support restore" "Could not restore application support"
    fi

    # Restore preferences
    if [[ -f "$backup_dir/com.postmanlabs.mac.plist" ]]; then
        cp "$backup_dir/com.postmanlabs.mac.plist" "$HOME/Library/Preferences/" || handle_error "Postman preferences restore" "Could not restore preferences"
    fi

    # Restore collections
    if [[ -d "$backup_dir/collections" ]]; then
        cp -R "$backup_dir/collections/" "$HOME/Postman/" 2>/dev/null || handle_error "Postman collections restore" "Could not restore collections"
    fi

    echo "✅ Postman configuration restored"
    echo "⚠️  You may need to sign in to your Postman account to sync cloud collections"
}

postman_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_POSTMAN:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file
        [ -d "$BACKUP_DIR/postman" ]
    fi
}
