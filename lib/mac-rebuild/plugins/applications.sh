#!/bin/bash

# Applications Plugin for Mac Rebuild
# Handles backup and restore of App Store applications and manual app listings

# Plugin metadata
applications_description() {
    echo "Manages App Store applications and application inventories"
}

applications_priority() {
    echo "30"  # After Homebrew but before VS Code
}

applications_backup() {
    log "Backing up App Store applications and application inventory..."

    local backup_dir="$BACKUP_DIR/apps"
    mkdir -p "$backup_dir"

    # Backup App Store applications
    if command -v mas &> /dev/null; then
        mas list > "$backup_dir/app_store_apps.txt" 2>/dev/null || handle_error "App Store apps" "Could not list App Store apps"
        echo "✅ App Store apps backed up"
    else
        echo "⚠️  mas (Mac App Store CLI) not found, skipping App Store backup..."
        echo "   Install with: brew install mas"
    fi

    # Backup manually installed applications
    log "Backing up list of installed applications..."
    ls /Applications > "$backup_dir/applications.txt" 2>/dev/null || handle_error "Applications" "Could not list applications"
    ls /Applications/Utilities > "$backup_dir/utilities.txt" 2>/dev/null || handle_error "Utilities" "Could not list utilities"

    echo "✅ Application inventory backed up"
}

applications_restore() {
    log "Restoring App Store applications..."

    local backup_dir="$BACKUP_DIR/apps"

    # Install mas first if not available
    if ! command -v mas &> /dev/null; then
        if command -v brew &> /dev/null; then
            brew install mas || handle_error "mas installation" "Could not install mas"
        else
            echo "⚠️  Homebrew not available, cannot install mas"
            return 1
        fi
    fi

    # Restore App Store applications
    if [ -f "$backup_dir/app_store_apps.txt" ]; then
        echo "App Store applications from backup:"
        cat "$backup_dir/app_store_apps.txt"
        echo ""
        echo "⚠️  App Store apps require manual installation or being signed in to the App Store"
        echo "   Use 'mas install <app_id>' to install apps from the list above"
    fi

    # Show application comparison
    if [ -f "$backup_dir/applications.txt" ]; then
        echo ""
        log "Application inventory comparison:"
        echo "Applications that were installed on your previous system:"
        cat "$backup_dir/applications.txt"
        echo ""
        echo "Current applications:"
        ls /Applications 2>/dev/null || true
    fi
}
