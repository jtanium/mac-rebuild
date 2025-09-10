#!/bin/bash

# Oh My Zsh Plugin for Mac Rebuild
# Handles backup and restore of Oh My Zsh framework, themes, plugins, and configurations

# Plugin metadata
oh_my_zsh_description() {
    echo "Manages Oh My Zsh framework, themes, plugins, and configurations"
}

oh_my_zsh_priority() {
    echo "30"  # After homebrew, before dotfiles
}

oh_my_zsh_init() {
    OMZ_DIR="$HOME/.oh-my-zsh"
    OMZ_CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"
}

oh_my_zsh_has_detection() {
    return 0
}

oh_my_zsh_detect() {
    [ -d "$OMZ_DIR" ] && [ -f "$OMZ_DIR/oh-my-zsh.sh" ]
}

oh_my_zsh_backup() {
    log "Backing up Oh My Zsh..."

    if ! oh_my_zsh_detect; then
        echo "⚠️  Oh My Zsh not found, skipping..."
        return 0
    fi

    local backup_dir="$BACKUP_DIR/oh-my-zsh"
    mkdir -p "$backup_dir"

    # Backup the entire custom directory (themes, plugins, configs)
    if [ -d "$OMZ_CUSTOM_DIR" ]; then
        cp -r "$OMZ_CUSTOM_DIR" "$backup_dir/custom" || handle_error "Oh My Zsh custom" "Could not backup custom directory"
    fi

    # Backup .zshrc if it exists and contains OMZ references
    if [ -f "$HOME/.zshrc" ] && grep -q "oh-my-zsh" "$HOME/.zshrc"; then
        cp "$HOME/.zshrc" "$backup_dir/zshrc" || handle_error "Oh My Zsh zshrc" "Could not backup .zshrc"
    fi

    # Save the current OMZ version/commit for reference
    if [ -d "$OMZ_DIR/.git" ]; then
        cd "$OMZ_DIR" && git rev-parse HEAD > "$backup_dir/omz_version" 2>/dev/null || true
    fi

    # Create a list of installed plugins and themes for reference
    if [ -d "$OMZ_CUSTOM_DIR/plugins" ]; then
        ls "$OMZ_CUSTOM_DIR/plugins" > "$backup_dir/custom_plugins.txt" 2>/dev/null || true
    fi

    if [ -d "$OMZ_CUSTOM_DIR/themes" ]; then
        ls "$OMZ_CUSTOM_DIR/themes" > "$backup_dir/custom_themes.txt" 2>/dev/null || true
    fi

    # Extract current theme and plugins from .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        grep "^ZSH_THEME=" "$HOME/.zshrc" > "$backup_dir/current_theme.txt" 2>/dev/null || true
        grep "^plugins=" "$HOME/.zshrc" > "$backup_dir/current_plugins.txt" 2>/dev/null || true
    fi

    echo "✅ Oh My Zsh backed up"
}

oh_my_zsh_restore() {
    log "Installing and restoring Oh My Zsh..."

    local backup_dir="$BACKUP_DIR/oh-my-zsh"

    # Install Oh My Zsh if not present
    if ! oh_my_zsh_detect; then
        echo "Installing Oh My Zsh..."

        # Install OMZ non-interactively
        export RUNZSH=no
        export CHSH=no
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || handle_error "Oh My Zsh installation" "Could not install Oh My Zsh"

        echo "✅ Oh My Zsh installed"
    else
        echo "✅ Oh My Zsh already installed"
    fi

    # Restore custom directory if backup exists
    if [ -d "$backup_dir/custom" ]; then
        echo "Restoring Oh My Zsh custom directory..."

        # Backup existing custom directory if it exists
        if [ -d "$OMZ_CUSTOM_DIR" ]; then
            mv "$OMZ_CUSTOM_DIR" "$OMZ_CUSTOM_DIR.bak.$(date +%Y%m%d_%H%M%S)"
        fi

        # Restore custom directory
        cp -r "$backup_dir/custom" "$OMZ_CUSTOM_DIR" || handle_error "Oh My Zsh custom restore" "Could not restore custom directory"
        echo "✅ Custom themes and plugins restored"
    fi

    # Restore .zshrc if backup exists and current .zshrc doesn't have OMZ config
    if [ -f "$backup_dir/zshrc" ]; then
        if [ ! -f "$HOME/.zshrc" ] || ! grep -q "oh-my-zsh" "$HOME/.zshrc"; then
            echo "Restoring Oh My Zsh configuration..."

            # Backup existing .zshrc if it exists
            if [ -f "$HOME/.zshrc" ]; then
                cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
            fi

            # Restore OMZ .zshrc
            cp "$backup_dir/zshrc" "$HOME/.zshrc" || handle_error "Oh My Zsh zshrc restore" "Could not restore .zshrc"
            echo "✅ Oh My Zsh configuration restored"
        else
            echo "⚠️  Existing .zshrc contains Oh My Zsh config, skipping restore (backup available at $backup_dir/zshrc)"
        fi
    fi

    # Set zsh as default shell if not already set
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Setting zsh as default shell..."
        chsh -s "$(which zsh)" || echo "⚠️  Could not change default shell to zsh. Please run: chsh -s $(which zsh)"
    fi

    echo "✅ Oh My Zsh restoration complete"

    # Show summary of what was restored
    oh_my_zsh_show_restore_summary "$backup_dir"
}

oh_my_zsh_show_restore_summary() {
    local backup_dir="$1"

    echo ""
    echo "📋 Oh My Zsh Restore Summary:"

    if [ -f "$backup_dir/current_theme.txt" ]; then
        echo "   Theme: $(cat "$backup_dir/current_theme.txt" | cut -d'=' -f2 | tr -d '"')"
    fi

    if [ -f "$backup_dir/custom_plugins.txt" ] && [ -s "$backup_dir/custom_plugins.txt" ]; then
        echo "   Custom Plugins: $(cat "$backup_dir/custom_plugins.txt" | tr '\n' ' ')"
    fi

    if [ -f "$backup_dir/custom_themes.txt" ] && [ -s "$backup_dir/custom_themes.txt" ]; then
        echo "   Custom Themes: $(cat "$backup_dir/custom_themes.txt" | tr '\n' ' ')"
    fi
}

# Oh My Zsh plugin for mac-rebuild
# Handles backup and restore of Oh My Zsh configuration

PLUGIN_NAME="oh-my-zsh"
PLUGIN_DESCRIPTION="Oh My Zsh shell framework configuration and custom themes/plugins"
PLUGIN_PRIORITY=30

plugin_enabled() {
    [[ -d "$HOME/.oh-my-zsh" ]]
}

plugin_backup() {
    local backup_dir="$1"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh not found, skipping backup"
        return 0
    fi

    echo "Backing up Oh My Zsh configuration..."

    # Create backup directory
    mkdir -p "$backup_dir/oh-my-zsh"

    # Backup custom themes and plugins
    if [[ -d "$HOME/.oh-my-zsh/custom" ]]; then
        cp -r "$HOME/.oh-my-zsh/custom" "$backup_dir/oh-my-zsh/"
    fi

    # Backup .zshrc for Oh My Zsh settings
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_dir/oh-my-zsh/"
    fi

    # Create a manifest of installed plugins and themes
    {
        echo "# Oh My Zsh Backup Manifest"
        echo "# Generated on $(date)"
        echo ""

        if [[ -f "$HOME/.zshrc" ]]; then
            echo "# Active theme:"
            grep "^ZSH_THEME=" "$HOME/.zshrc" || echo "ZSH_THEME=robbyrussell"
            echo ""

            echo "# Active plugins:"
            grep "^plugins=" "$HOME/.zshrc" || echo "plugins=(git)"
            echo ""
        fi

        echo "# Custom themes available:"
        if [[ -d "$HOME/.oh-my-zsh/custom/themes" ]]; then
            ls -1 "$HOME/.oh-my-zsh/custom/themes"/*.zsh-theme 2>/dev/null | xargs -I {} basename {} .zsh-theme || echo "None"
        else
            echo "None"
        fi
        echo ""

        echo "# Custom plugins available:"
        if [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
            ls -1 "$HOME/.oh-my-zsh/custom/plugins" 2>/dev/null || echo "None"
        else
            echo "None"
        fi
    } > "$backup_dir/oh-my-zsh/manifest.txt"

    echo "✅ Oh My Zsh configuration backed up"
    return 0
}

plugin_restore() {
    local backup_dir="$1"

    echo "Restoring Oh My Zsh configuration..."

    # Check if Oh My Zsh backup exists
    if [[ ! -d "$backup_dir/oh-my-zsh" ]]; then
        echo "No Oh My Zsh backup found, skipping restore"
        return 0
    fi

    # Install Oh My Zsh if not present
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "Installing Oh My Zsh..."

        # Download and install Oh My Zsh
        if command -v curl >/dev/null; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        elif command -v wget >/dev/null; then
            sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
        else
            echo "❌ Error: curl or wget required to install Oh My Zsh"
            return 1
        fi

        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            echo "❌ Error: Oh My Zsh installation failed"
            return 1
        fi

        echo "✅ Oh My Zsh installed successfully"
    fi

    # Restore custom configuration
    if [[ -d "$backup_dir/oh-my-zsh/custom" ]]; then
        echo "Restoring custom themes and plugins..."
        cp -r "$backup_dir/oh-my-zsh/custom"/* "$HOME/.oh-my-zsh/custom/" 2>/dev/null || true
    fi

    # Restore .zshrc if it exists in backup
    if [[ -f "$backup_dir/oh-my-zsh/.zshrc" ]]; then
        echo "Restoring .zshrc configuration..."

        # Backup existing .zshrc if it exists
        if [[ -f "$HOME/.zshrc" ]]; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        cp "$backup_dir/oh-my-zsh/.zshrc" "$HOME/"
    fi

    # Show restore summary
    if [[ -f "$backup_dir/oh-my-zsh/manifest.txt" ]]; then
        echo ""
        echo "📋 Oh My Zsh Restore Summary:"
        cat "$backup_dir/oh-my-zsh/manifest.txt"
        echo ""
    fi

    echo "✅ Oh My Zsh configuration restored"
    echo "💡 Run 'source ~/.zshrc' or restart your terminal to apply changes"

    return 0
}

plugin_status() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "✅ Oh My Zsh is installed"

        if [[ -f "$HOME/.zshrc" ]]; then
            local theme=$(grep "^ZSH_THEME=" "$HOME/.zshrc" 2>/dev/null | cut -d'"' -f2 || echo "unknown")
            local plugins=$(grep "^plugins=" "$HOME/.zshrc" 2>/dev/null | sed 's/plugins=(//' | sed 's/)//' || echo "unknown")

            echo "   Theme: $theme"
            echo "   Plugins: $plugins"

            if [[ -d "$HOME/.oh-my-zsh/custom/themes" ]]; then
                local custom_themes=$(ls -1 "$HOME/.oh-my-zsh/custom/themes"/*.zsh-theme 2>/dev/null | wc -l | tr -d ' ')
                echo "   Custom themes: $custom_themes"
            fi

            if [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
                local custom_plugins=$(ls -1 "$HOME/.oh-my-zsh/custom/plugins" 2>/dev/null | wc -l | tr -d ' ')
                echo "   Custom plugins: $custom_plugins"
            fi
        fi
    else
        echo "❌ Oh My Zsh is not installed"
    fi
}

