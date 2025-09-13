#!/bin/bash

# Sublime Text Plugin for Mac Rebuild
# Handles backup and restore of Sublime Text settings, packages, and preferences

# Plugin metadata
sublime_text_description() {
    echo "Manages Sublime Text editor settings, packages, and user preferences"
}

sublime_text_priority() {
    echo "40"  # After core tools
}

sublime_text_has_detection() {
    return 0
}

sublime_text_detect() {
    [[ -d "/Applications/Sublime Text.app" ]] || \
    [[ -d "/Applications/Sublime Text 3.app" ]] || \
    [[ -d "/Applications/Sublime Text 4.app" ]] || \
    (command -v brew &> /dev/null && brew list sublime-text &>/dev/null)
}

sublime_text_backup() {
    log "Checking for Sublime Text..."

    if ! sublime_text_detect; then
        echo "Sublime Text not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Sublime Text. Do you want to backup Sublime Text settings and packages?" "y"; then
        echo "INCLUDE_SUBLIME_TEXT:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/sublime_text"
        mkdir -p "$backup_dir"

        # Backup Sublime Text user settings (version 3 and 4)
        local sublime_paths=(
            "$HOME/Library/Application Support/Sublime Text 3/Packages/User"
            "$HOME/Library/Application Support/Sublime Text/Packages/User"
        )

        for path in "${sublime_paths[@]}"; do
            if [[ -d "$path" ]]; then
                local version_dir=$(basename "$(dirname "$(dirname "$path")")")
                mkdir -p "$backup_dir/$version_dir"
                cp -R "$path/" "$backup_dir/$version_dir/User/" 2>/dev/null || handle_error "Sublime Text $version_dir User settings" "Could not backup User settings"

                # Also backup installed packages list
                if [[ -f "$(dirname "$path")/User/Package Control.sublime-settings" ]]; then
                    cp "$(dirname "$path")/User/Package Control.sublime-settings" "$backup_dir/$version_dir/" 2>/dev/null || handle_error "Sublime Text Package Control settings" "Could not backup Package Control settings"
                fi

                echo "✅ Sublime Text $version_dir settings backed up"
            fi
        done

        # Backup license file if it exists
        local license_paths=(
            "$HOME/Library/Application Support/Sublime Text 3/Local/License.sublime_license"
            "$HOME/Library/Application Support/Sublime Text/Local/License.sublime_license"
        )

        for license_path in "${license_paths[@]}"; do
            if [[ -f "$license_path" ]]; then
                local version_dir=$(basename "$(dirname "$(dirname "$license_path")")")
                mkdir -p "$backup_dir/$version_dir"
                cp "$license_path" "$backup_dir/$version_dir/" 2>/dev/null || handle_error "Sublime Text license" "Could not backup license"
                echo "✅ Sublime Text license backed up"
            fi
        done

        if [[ ! -d "$backup_dir/Sublime Text 3" ]] && [[ ! -d "$backup_dir/Sublime Text" ]]; then
            echo "⚠️  No Sublime Text configuration found to backup"
        fi
    else
        echo "EXCLUDE_SUBLIME_TEXT:true" >> "$USER_PREFS"
    fi
}

sublime_text_restore() {
    # Check if Sublime Text should be restored
    if ! sublime_text_should_restore; then
        return 0
    fi

    log "Restoring Sublime Text configuration..."

    local backup_dir="$BACKUP_DIR/sublime_text"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No Sublime Text backup found, skipping..."
        return 0
    fi

    # Ensure Sublime Text is installed (install if missing)
    if ! sublime_text_detect; then
        if ask_yes_no "Sublime Text not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask sublime-text || handle_error "Sublime Text installation" "Could not install Sublime Text"
                echo "✅ Sublime Text installed"
            else
                echo "❌ Homebrew not available. Please install Sublime Text manually from https://www.sublimetext.com/"
                return 1
            fi
        else
            echo "Skipping Sublime Text restore without Sublime Text installed"
            return 0
        fi
    fi

    # Restore settings for each backed up version
    for version_backup in "$backup_dir"/*; do
        if [[ -d "$version_backup" ]]; then
            local version_name=$(basename "$version_backup")
            local target_dir="$HOME/Library/Application Support/$version_name"

            # Restore User settings
            if [[ -d "$version_backup/User" ]]; then
                mkdir -p "$target_dir/Packages/"
                cp -R "$version_backup/User/" "$target_dir/Packages/User/" 2>/dev/null || handle_error "Sublime Text $version_name User settings restore" "Could not restore User settings"
                echo "✅ Sublime Text $version_name User settings restored"
            fi

            # Restore Package Control settings
            if [[ -f "$version_backup/Package Control.sublime-settings" ]]; then
                mkdir -p "$target_dir/Packages/User/"
                cp "$version_backup/Package Control.sublime-settings" "$target_dir/Packages/User/" || handle_error "Sublime Text Package Control restore" "Could not restore Package Control settings"
                echo "✅ Sublime Text Package Control settings restored"
            fi

            # Restore license
            if [[ -f "$version_backup/License.sublime_license" ]]; then
                mkdir -p "$target_dir/Local/"
                cp "$version_backup/License.sublime_license" "$target_dir/Local/" || handle_error "Sublime Text license restore" "Could not restore license"
                echo "✅ Sublime Text license restored"
            fi
        fi
    done

    echo "⚠️  Package Control will automatically install packages on first launch"
}

sublime_text_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_SUBLIME_TEXT:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file
        [ -d "$BACKUP_DIR/sublime_text" ]
    fi
}
