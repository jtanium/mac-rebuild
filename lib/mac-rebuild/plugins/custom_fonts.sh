#!/bin/bash

# Custom Fonts Plugin for Mac Rebuild
# Handles backup and restore of user-installed fonts and automatic installation of common development fonts

# Plugin metadata
custom_fonts_description() {
    echo "Manages user-installed fonts and development font packages"
}

custom_fonts_priority() {
    echo "25"  # Before iTerm and Oh My Zsh to ensure fonts are available
}

custom_fonts_has_detection() {
    return 0
}

custom_fonts_detect() {
    # Always return true - fonts are always relevant
    return 0
}

custom_fonts_backup() {
    log "Backing up custom fonts..."

    local backup_dir="$BACKUP_DIR/fonts"
    mkdir -p "$backup_dir"

    # Backup user fonts
    local fonts_dir="$HOME/Library/Fonts"
    if [[ -d "$fonts_dir" ]] && [[ -n "$(ls -A "$fonts_dir" 2>/dev/null)" ]]; then
        echo "Found $(ls "$fonts_dir" | wc -l) user fonts..."
        cp "$fonts_dir/"* "$backup_dir/" 2>/dev/null || true

        # Create a list of fonts for reference
        ls "$fonts_dir" > "$backup_dir/font_list.txt" 2>/dev/null || true

        # Detect common development fonts
        custom_fonts_detect_dev_fonts "$fonts_dir" "$backup_dir"

        echo "✅ User fonts backed up"
    else
        echo "No user fonts found to backup"
        touch "$backup_dir/.no_fonts"
    fi
}

custom_fonts_restore() {
    log "Restoring custom fonts..."

    local backup_dir="$BACKUP_DIR/fonts"

    if [ ! -d "$backup_dir" ] || [ -f "$backup_dir/.no_fonts" ]; then
        echo "No font backup found, checking for development font needs..."
        custom_fonts_install_dev_fonts
        return 0
    fi

    # Create fonts directory if it doesn't exist
    mkdir -p "$HOME/Library/Fonts"

    # Restore user fonts
    if ls "$backup_dir"/*.{ttf,otf,ttc,woff,woff2} 1> /dev/null 2>&1; then
        echo "Restoring $(ls "$backup_dir"/*.{ttf,otf,ttc,woff,woff2} 2>/dev/null | wc -l) fonts..."
        cp "$backup_dir"/*.{ttf,otf,ttc,woff,woff2} "$HOME/Library/Fonts/" 2>/dev/null || true
        echo "✅ User fonts restored"
    fi

    # Install any missing development fonts
    custom_fonts_install_dev_fonts

    echo "✅ Font restoration complete"
}

custom_fonts_detect_dev_fonts() {
    local fonts_dir="$1"
    local backup_dir="$2"

    # Detect common development fonts and save metadata
    echo "# Development fonts detected during backup" > "$backup_dir/dev_fonts.txt"

    # Check for Nerd Fonts (Oh My Zsh themes)
    if ls "$fonts_dir"/*Nerd*.{ttf,otf} 1> /dev/null 2>&1; then
        echo "NERD_FONTS=true" >> "$backup_dir/dev_fonts.txt"
    fi

    # Check for JetBrains fonts
    if ls "$fonts_dir"/*{JetBrains,jetbrains,Intel}*.{ttf,otf} 1> /dev/null 2>&1; then
        echo "JETBRAINS_FONTS=true" >> "$backup_dir/dev_fonts.txt"
        # List specific JetBrains fonts
        find "$fonts_dir" -name "*[Jj]et[Bb]rains*" -o -name "*[Ii]ntel*" | sed "s|$fonts_dir/||" > "$backup_dir/jetbrains_fonts.txt" 2>/dev/null || true
    fi

    # Check for Powerline fonts
    if ls "$fonts_dir"/*{Powerline,powerline}*.{ttf,otf} 1> /dev/null 2>&1; then
        echo "POWERLINE_FONTS=true" >> "$backup_dir/dev_fonts.txt"
    fi

    # Check for Source Code Pro
    if ls "$fonts_dir"/*{Source,source}*.{ttf,otf} 1> /dev/null 2>&1; then
        echo "SOURCE_CODE_PRO=true" >> "$backup_dir/dev_fonts.txt"
    fi
}

custom_fonts_install_dev_fonts() {
    local backup_dir="$BACKUP_DIR/fonts"

    if ! command -v brew &> /dev/null; then
        echo "⚠️  Homebrew not available, skipping automatic font installation"
        return 0
    fi

    # Tap font casks if not already done
    brew tap homebrew/cask-fonts 2>/dev/null || true

    # Check what development fonts we need based on other plugins
    local needs_nerd_fonts=false
    local needs_jetbrains_fonts=false

    # Check if Oh My Zsh uses themes that need Nerd Fonts
    if [ -f "$BACKUP_DIR/oh-my-zsh/current_theme.txt" ]; then
        local theme
        theme=$(cat "$BACKUP_DIR/oh-my-zsh/current_theme.txt" | cut -d'=' -f2 | tr -d '"' 2>/dev/null || echo "")
        case "$theme" in
            "powerlevel9k"|"powerlevel10k"|"agnoster"|"spaceship"|"bullet-train"|"geometry")
                needs_nerd_fonts=true
                ;;
        esac
    fi

    # Check if custom Oh My Zsh themes need fonts
    if [ -d "$BACKUP_DIR/oh-my-zsh/custom/themes" ]; then
        if find "$BACKUP_DIR/oh-my-zsh/custom/themes" -name "*.zsh-theme" -exec grep -l "powerline\|nerd\|patched" {} + >/dev/null 2>&1; then
            needs_nerd_fonts=true
        fi
    fi

    # Check if JetBrains IDEs are backed up
    if [ -d "$BACKUP_DIR/jetbrains" ] || [ -f "$USER_PREFS" ] && grep -q "INCLUDE_JETBRAINS:true" "$USER_PREFS" 2>/dev/null; then
        needs_jetbrains_fonts=true
    fi

    # Check if we had these fonts before (from backup metadata)
    if [ -f "$backup_dir/dev_fonts.txt" ]; then
        if grep -q "NERD_FONTS=true" "$backup_dir/dev_fonts.txt"; then
            needs_nerd_fonts=true
        fi
        if grep -q "JETBRAINS_FONTS=true" "$backup_dir/dev_fonts.txt"; then
            needs_jetbrains_fonts=true
        fi
    fi

    # Install fonts based on needs
    if [ "$needs_nerd_fonts" = true ]; then
        custom_fonts_install_nerd_fonts
    fi

    if [ "$needs_jetbrains_fonts" = true ]; then
        custom_fonts_install_jetbrains_fonts
    fi
}

custom_fonts_install_nerd_fonts() {
    echo "🔤 Installing Nerd Fonts for Oh My Zsh themes..."

    if ask_yes_no "Install Nerd Fonts? (Required for Powerline themes like Powerlevel10k)" "y"; then
        brew install --cask font-meslo-lg-nerd-font || echo "⚠️  Could not install MesloLGS Nerd Font"
        brew install --cask font-hack-nerd-font || echo "⚠️  Could not install Hack Nerd Font"
        echo "✅ Nerd Fonts installed"
        echo "   💡 Configure your terminal to use 'MesloLGS NF' or 'Hack Nerd Font'"
    fi
}

custom_fonts_install_jetbrains_fonts() {
    echo "🔤 Installing JetBrains development fonts..."

    if ask_yes_no "Install JetBrains Mono font? (Recommended for JetBrains IDEs and development)" "y"; then
        brew install --cask font-jetbrains-mono || echo "⚠️  Could not install JetBrains Mono font"
        brew install --cask font-jetbrains-mono-nerd-font || echo "⚠️  Could not install JetBrains Mono Nerd Font"
        echo "✅ JetBrains fonts installed"
        echo "   💡 Configure your IDE to use 'JetBrains Mono' font"
    fi
}

custom_fonts_should_restore() {
    # Always restore fonts if backup exists
    [ -d "$BACKUP_DIR/fonts" ]
}
