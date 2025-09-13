#!/bin/bash

# VS Code Plugin for Mac Rebuild
# Handles backup and restore of VS Code settings, extensions, and keybindings

# Plugin metadata
vscode_description() {
    echo "Manages Visual Studio Code settings, extensions, and keybindings"
}

vscode_priority() {
    echo "40"  # After core tools
}

vscode_has_detection() {
    return 0
}

vscode_detect() {
    [[ -d "/Applications/Visual Studio Code.app" ]] || \
    [[ -d "/Applications/Visual Studio Code - Insiders.app" ]] || \
    [[ -d "/Applications/VSCodium.app" ]] || \
    (command -v brew &> /dev/null && brew list visual-studio-code &>/dev/null)
}

vscode_backup() {
    log "Checking for VS Code..."

    if ! vscode_detect; then
        echo "VS Code not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Visual Studio Code. Do you want to backup VS Code settings and extensions?" "y"; then
        echo "INCLUDE_VSCODE:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/vscode"
        mkdir -p "$backup_dir"

        # Find VS Code user directory
        local vscode_user_dir=""
        if [[ -d "$HOME/Library/Application Support/Code/User" ]]; then
            vscode_user_dir="$HOME/Library/Application Support/Code/User"
        elif [[ -d "$HOME/Library/Application Support/Code - Insiders/User" ]]; then
            vscode_user_dir="$HOME/Library/Application Support/Code - Insiders/User"
        fi

        if [[ -n "$vscode_user_dir" ]]; then
            # Backup settings and keybindings
            cp "$vscode_user_dir/settings.json" "$backup_dir/" 2>/dev/null || handle_error "VS Code settings" "Could not copy settings.json"
            cp "$vscode_user_dir/keybindings.json" "$backup_dir/" 2>/dev/null || handle_error "VS Code keybindings" "Could not copy keybindings.json"
            cp "$vscode_user_dir/snippets/"* "$backup_dir/" 2>/dev/null || true

            # Backup extensions list
            if command -v code &> /dev/null; then
                code --list-extensions > "$backup_dir/extensions.txt" 2>/dev/null || handle_error "VS Code extensions" "Could not list extensions"
            fi

            echo "✅ VS Code configuration backed up"
        fi
    else
        echo "EXCLUDE_VSCODE:true" >> "$USER_PREFS"
    fi
}

vscode_restore() {
    # Check if VS Code should be restored
    if ! vscode_should_restore; then
        return 0
    fi

    log "Restoring VS Code configuration..."

    local backup_dir="$BACKUP_DIR/vscode"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No VS Code backup found, skipping..."
        return 0
    fi

    # Ensure VS Code is installed (install if missing)
    if ! vscode_detect; then
        if ask_yes_no "VS Code not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask visual-studio-code || handle_error "VS Code installation" "Could not install VS Code"
                echo "✅ VS Code installed"
            else
                echo "❌ Homebrew not available. Please install VS Code manually from https://code.visualstudio.com/"
                return 1
            fi
        else
            echo "Skipping VS Code restore without VS Code installed"
            return 0
        fi
    fi

    # Find VS Code user directory
    local vscode_user_dir="$HOME/Library/Application Support/Code/User"
    mkdir -p "$vscode_user_dir"
    mkdir -p "$vscode_user_dir/snippets"

    # Restore settings
    if [ -f "$backup_dir/settings.json" ]; then
        cp "$backup_dir/settings.json" "$vscode_user_dir/" || handle_error "VS Code settings restore" "Could not restore settings.json"
    fi

    # Restore keybindings
    if [ -f "$backup_dir/keybindings.json" ]; then
        cp "$backup_dir/keybindings.json" "$vscode_user_dir/" || handle_error "VS Code keybindings restore" "Could not restore keybindings.json"
    fi

    # Restore extensions
    if [ -f "$backup_dir/extensions.txt" ] && command -v code &> /dev/null; then
        echo "Installing VS Code extensions..."
        while IFS= read -r extension; do
            if [ -n "$extension" ]; then
                echo "Installing extension: $extension"
                code --install-extension "$extension" || handle_error "VS Code extension" "Could not install extension: $extension"
            fi
        done < "$backup_dir/extensions.txt"
    fi

    echo "✅ VS Code configuration restored"
}

vscode_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_VSCODE:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file
        [ -d "$BACKUP_DIR/vscode" ]
    fi
}
