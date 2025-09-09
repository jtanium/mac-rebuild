#!/bin/bash

# SSH Keys Plugin for Mac Rebuild
# Handles backup and restore of SSH keys and configuration

# Plugin metadata
ssh_description() {
    echo "Manages SSH keys and configuration (handle with care)"
}

ssh_priority() {
    echo "60"  # After dotfiles, high security concern
}

ssh_backup() {
    log "Backing up SSH keys..."

    if [ ! -d "$HOME/.ssh" ]; then
        echo "⚠️  No SSH directory found"
        return 0
    fi

    local backup_dir="$BACKUP_DIR/ssh_keys"

    if ask_yes_no "Found SSH keys. Include in backup? (Handle with care!)" "y"; then
        mkdir -p "$backup_dir"
        cp -r "$HOME/.ssh" "$backup_dir/" 2>/dev/null || handle_error "SSH keys" "Could not copy SSH directory"
        echo "✅ SSH keys backed up (handle with care!)"
        echo "INCLUDE_SSH:true" >> "$USER_PREFS"
    else
        echo "SSH keys excluded from backup"
        echo "EXCLUDE_SSH:true" >> "$USER_PREFS"
    fi
}

ssh_restore() {
    # Check if SSH should be restored
    if ! ssh_should_restore; then
        return 0
    fi

    log "Restoring SSH keys..."

    local backup_dir="$BACKUP_DIR/ssh_keys/.ssh"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No SSH backup found, skipping..."
        return 0
    fi

    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"

    # Restore SSH files with proper permissions
    cp -r "$backup_dir"/* "$HOME/.ssh/" 2>/dev/null || handle_error "SSH restore" "Could not restore SSH files"

    # Set proper permissions
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
    chmod 644 "$HOME/.ssh"/*.pub 2>/dev/null || true
    chmod 644 "$HOME/.ssh/config" 2>/dev/null || true
    chmod 644 "$HOME/.ssh/known_hosts" 2>/dev/null || true

    echo "✅ SSH keys restored with proper permissions"
}

ssh_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_SSH:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file but backup exists
        [ -d "$BACKUP_DIR/ssh_keys" ]
    fi
}
