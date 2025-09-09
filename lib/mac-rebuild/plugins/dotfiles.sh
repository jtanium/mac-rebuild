#!/bin/bash

# Dotfiles Plugin for Mac Rebuild
# Handles backup and restore of important configuration files

# Plugin metadata
dotfiles_description() {
    echo "Manages important dotfiles and configuration files"
}

dotfiles_priority() {
    echo "50"  # After applications
}

dotfiles_backup() {
    log "Backing up dotfiles and configurations..."

    local backup_dir="$BACKUP_DIR/dotfiles"
    mkdir -p "$backup_dir"

    # Standard dotfiles to backup
    local dotfiles=(
        ".zshrc"
        ".bashrc"
        ".bash_profile"
        ".gitconfig"
        ".gitignore_global"
        ".ssh/config"
        ".aws/config"
        ".aws/credentials"
        ".tool-versions"
        ".npmrc"
        ".yarnrc"
        ".gemrc"
    )

    for file in "${dotfiles[@]}"; do
        if [ -f "$HOME/$file" ]; then
            mkdir -p "$backup_dir/$(dirname "$file")"
            cp "$HOME/$file" "$backup_dir/$file" 2>/dev/null || handle_error "Dotfile $file" "Could not copy $file"
        fi
    done

    echo "✅ Dotfiles backed up"
}

dotfiles_restore() {
    log "Restoring dotfiles and configurations..."

    local backup_dir="$BACKUP_DIR/dotfiles"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No dotfiles backup found, skipping..."
        return 0
    fi

    # Restore all backed up dotfiles
    find "$backup_dir" -type f | while read -r backup_file; do
        # Get relative path from backup directory
        local relative_path="${backup_file#$backup_dir/}"
        local target_file="$HOME/$relative_path"

        # Create directory if needed
        mkdir -p "$(dirname "$target_file")"

        # Copy file with backup of existing
        if [ -f "$target_file" ]; then
            cp "$target_file" "$target_file.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        fi

        cp "$backup_file" "$target_file" || handle_error "Dotfile restore" "Could not restore $relative_path"
    done

    echo "✅ Dotfiles restored (existing files backed up with timestamp)"
}
