#!/bin/bash

# JetBrains Plugin for Mac Rebuild
# Handles backup and restore of JetBrains IDE configurations and applications

# Plugin metadata
jetbrains_description() {
    echo "Manages JetBrains IDE configurations, settings, and applications"
}

jetbrains_priority() {
    echo "45"  # After VS Code
}

# JetBrains IDE detection mapping - using functions for compatibility
jetbrains_get_cask_for_app() {
    local app_name="$1"
    case "$app_name" in
        "IntelliJ IDEA Ultimate.app") echo "intellij-idea" ;;
        "IntelliJ IDEA Community Edition.app") echo "intellij-idea-ce" ;;
        "IntelliJ IDEA.app") echo "intellij-idea" ;;
        "GoLand.app") echo "goland" ;;
        "RubyMine.app") echo "rubymine" ;;
        "WebStorm.app") echo "webstorm" ;;
        "PyCharm Professional Edition.app") echo "pycharm" ;;
        "PyCharm Community Edition.app") echo "pycharm-ce" ;;
        "PyCharm.app") echo "pycharm" ;;
        "CLion.app") echo "clion" ;;
        "PhpStorm.app") echo "phpstorm" ;;
        "DataGrip.app") echo "datagrip" ;;
        "AppCode.app") echo "appcode" ;;
        "Rider.app") echo "rider" ;;
        "Android Studio.app") echo "android-studio" ;;
        *) echo "" ;;
    esac
}

jetbrains_get_all_app_names() {
    echo "IntelliJ IDEA Ultimate.app"
    echo "IntelliJ IDEA Community Edition.app"
    echo "IntelliJ IDEA.app"
    echo "GoLand.app"
    echo "RubyMine.app"
    echo "WebStorm.app"
    echo "PyCharm Professional Edition.app"
    echo "PyCharm Community Edition.app"
    echo "PyCharm.app"
    echo "CLion.app"
    echo "PhpStorm.app"
    echo "DataGrip.app"
    echo "AppCode.app"
    echo "Rider.app"
    echo "Android Studio.app"
}

jetbrains_has_detection() {
    return 0
}

jetbrains_detect() {
    jetbrains_get_all_app_names | while IFS= read -r app_name; do
        if [ -d "/Applications/$app_name" ]; then
            return 0
        fi
    done
    return 1
}

jetbrains_backup() {
    log "Backing up JetBrains IDE configurations..."

    if ! jetbrains_detect; then
        echo "⚠️  No JetBrains IDEs found, skipping..."
        return 0
    fi

    if ask_yes_no "Found JetBrains IDEs. Do you want to backup IDE settings and application list?" "y"; then
        echo "INCLUDE_JETBRAINS:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/jetbrains"
        mkdir -p "$backup_dir"

        # Detect and save installed IDEs
        jetbrains_backup_installed_ides "$backup_dir"

        # Backup JetBrains settings
        jetbrains_backup_settings "$backup_dir"

        echo "✅ JetBrains IDE configurations and application list backed up"
    else
        echo "EXCLUDE_JETBRAINS:true" >> "$USER_PREFS"
    fi
}

jetbrains_backup_installed_ides() {
    local backup_dir="$1"
    local ides_file="$backup_dir/installed_ides.txt"

    echo "# JetBrains IDEs installed on this system" > "$ides_file"
    echo "# Format: app_name:homebrew_cask" >> "$ides_file"

    local found_count=0
    jetbrains_get_all_app_names | while IFS= read -r app_name; do
        if [ -d "/Applications/$app_name" ]; then
            local cask_name=$(jetbrains_get_cask_for_app "$app_name")
            if [ -n "$cask_name" ]; then
                echo "$app_name:$cask_name" >> "$ides_file"
                echo "  📱 Found: $app_name (will restore as: $cask_name)"
                found_count=$((found_count + 1))
            fi
        fi
    done

    # Count actual findings since we can't modify variables in subshells
    local actual_count=$(grep -v "^#" "$ides_file" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$actual_count" -eq 0 ]; then
        echo "  ⚠️  No JetBrains IDEs detected in /Applications"
    else
        echo "  ✅ Detected $actual_count JetBrains IDE(s)"
    fi
}

jetbrains_backup_settings() {
    local backup_dir="$1"
    local jetbrains_support_dir="$HOME/Library/Application Support/JetBrains"

    if [ ! -d "$jetbrains_support_dir" ]; then
        echo "  ⚠️  No JetBrains settings directory found"
        return 0
    fi

    # Create a list of IDE directories
    find "$jetbrains_support_dir" -maxdepth 1 -type d -name "*" | grep -E "(IntelliJIdea|GoLand|RubyMine|WebStorm|PyCharm|CLion|PhpStorm|DataGrip|AppCode|Rider|AndroidStudio)" > "$backup_dir/ide_directories.txt" 2>/dev/null || true

    # Backup key configuration files from each IDE
    while IFS= read -r ide_dir; do
        if [ -d "$ide_dir" ] && [ -n "$ide_dir" ]; then
            local ide_name=$(basename "$ide_dir")
            echo "  🔧 Backing up $ide_name settings..."

            mkdir -p "$backup_dir/$ide_name"

            # Backup common settings
            for config_dir in "$ide_dir"/*/; do
                if [ -d "$config_dir" ]; then
                    local config_name=$(basename "$config_dir")

                    # Backup key configuration directories
                    for settings_type in "options" "colors" "keymaps" "templates" "tools" "codestyles"; do
                        if [ -d "$config_dir/$settings_type" ]; then
                            mkdir -p "$backup_dir/$ide_name/$config_name"
                            cp -r "$config_dir/$settings_type" "$backup_dir/$ide_name/$config_name/" 2>/dev/null || true
                        fi
                    done

                    # Backup individual important files
                    for settings_file in "options/editor.xml" "options/ide.general.xml" "options/keymap.xml" "options/colors.scheme.xml"; do
                        if [ -f "$config_dir/$settings_file" ]; then
                            mkdir -p "$backup_dir/$ide_name/$config_name/$(dirname "$settings_file")"
                            cp "$config_dir/$settings_file" "$backup_dir/$ide_name/$config_name/$settings_file" 2>/dev/null || true
                        fi
                    done
                fi
            done
        fi
    done < "$backup_dir/ide_directories.txt"
}

jetbrains_restore() {
    # Check if JetBrains should be restored
    if ! jetbrains_should_restore; then
        return 0
    fi

    log "Restoring JetBrains IDEs and configurations..."

    local backup_dir="$BACKUP_DIR/jetbrains"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No JetBrains backup found, skipping..."
        return 0
    fi

    # First, restore the IDE applications through Homebrew
    jetbrains_restore_applications "$backup_dir"

    # Then restore settings
    jetbrains_restore_settings "$backup_dir"
}

jetbrains_restore_applications() {
    local backup_dir="$1"
    local ides_file="$backup_dir/installed_ides.txt"

    if [ ! -f "$ides_file" ]; then
        echo "⚠️  No IDE installation list found, skipping application restore"
        return 0
    fi

    log "Installing JetBrains IDEs through Homebrew..."

    # Check if Homebrew is available
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not available, cannot install JetBrains IDEs"
        return 1
    fi

    local install_count=0
    local skip_count=0

    while IFS=: read -r app_name cask_name; do
        if [ -n "$app_name" ] && [ -n "$cask_name" ] && [[ ! "$app_name" =~ ^# ]]; then
            echo "🔧 Installing $app_name via Homebrew cask: $cask_name"

            # Check if already installed
            if [ -d "/Applications/$app_name" ]; then
                echo "  ✅ $app_name already installed, skipping"
                skip_count=$((skip_count + 1))
                continue
            fi

            # Install the IDE
            if brew install --cask "$cask_name"; then
                echo "  ✅ Successfully installed $app_name"
                install_count=$((install_count + 1))
            else
                echo "  ❌ Failed to install $app_name (cask: $cask_name)"
                echo "     You can install manually with: brew install --cask $cask_name"
            fi
        fi
    done < "$ides_file"

    echo ""
    echo "📊 JetBrains IDE Installation Summary:"
    echo "  ✅ Installed: $install_count"
    echo "  ⏭️  Skipped (already present): $skip_count"

    if [ $install_count -gt 0 ]; then
        echo "  ⏳ Note: IDEs may take a moment to appear in Applications folder"
    fi
}

jetbrains_restore_settings() {
    local backup_dir="$1"
    local jetbrains_support_dir="$HOME/Library/Application Support/JetBrains"

    if [ ! -f "$backup_dir/ide_directories.txt" ]; then
        echo "⚠️  No IDE settings backup found, skipping settings restore"
        return 0
    fi

    log "Restoring JetBrains IDE settings..."
    mkdir -p "$jetbrains_support_dir"

    # Restore each IDE's settings
    for ide_backup_dir in "$backup_dir"/*/; do
        if [ -d "$ide_backup_dir" ]; then
            local ide_name=$(basename "$ide_backup_dir")

            # Skip files that aren't IDE directories
            if [[ "$ide_name" =~ \.(txt|xml)$ ]]; then
                continue
            fi

            echo "🔧 Restoring $ide_name settings..."

            # Find or create the corresponding IDE directory
            local target_ide_dir="$jetbrains_support_dir/$ide_name"

            # If the exact directory doesn't exist, try to find a similar one
            if [ ! -d "$target_ide_dir" ]; then
                # Look for directories with similar names (version differences)
                local similar_dir=$(find "$jetbrains_support_dir" -maxdepth 1 -type d -name "${ide_name%.*}*" | head -1)
                if [ -n "$similar_dir" ]; then
                    target_ide_dir="$similar_dir"
                    echo "  📁 Using similar directory: $(basename "$target_ide_dir")"
                else
                    echo "  📁 Creating new directory: $target_ide_dir"
                    mkdir -p "$target_ide_dir"
                fi
            fi

            # Restore configuration files
            if [ -d "$target_ide_dir" ]; then
                cp -r "$ide_backup_dir"/* "$target_ide_dir/" 2>/dev/null || handle_error "JetBrains $ide_name" "Could not restore settings"
                echo "  ✅ Settings restored for $ide_name"
            else
                echo "  ⚠️  Could not create target directory for $ide_name"
            fi
        fi
    done

    echo "✅ JetBrains IDE settings restoration completed"
}

jetbrains_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_JETBRAINS:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file but backup exists
        [ -d "$BACKUP_DIR/jetbrains" ]
    fi
}
