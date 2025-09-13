#!/bin/bash

# Android Studio Plugin for Mac Rebuild
# Handles backup and restore of Android Studio settings, projects, and SDKs

# Plugin metadata
android_studio_description() {
    echo "Manages Android Studio IDE settings, projects, and SDK configurations"
}

android_studio_priority() {
    echo "45"  # After core tools and VS Code
}

android_studio_has_detection() {
    return 0
}

android_studio_detect() {
    [[ -d "/Applications/Android Studio.app" ]] || \
    (command -v brew &> /dev/null && brew list android-studio &>/dev/null)
}

android_studio_backup() {
    log "Checking for Android Studio..."

    if ! android_studio_detect; then
        echo "Android Studio not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Android Studio. Do you want to backup Android Studio settings and projects?" "y"; then
        echo "INCLUDE_ANDROID_STUDIO:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/android_studio"
        mkdir -p "$backup_dir"

        # Backup Android Studio settings
        if [[ -d "$HOME/Library/Application Support/Google/AndroidStudio" ]]; then
            cp -R "$HOME/Library/Application Support/Google/AndroidStudio/" "$backup_dir/settings/" 2>/dev/null || handle_error "Android Studio settings" "Could not backup settings"
        fi

        # Backup preferences
        if [[ -d "$HOME/Library/Preferences/AndroidStudio" ]]; then
            cp -R "$HOME/Library/Preferences/AndroidStudio/" "$backup_dir/preferences/" 2>/dev/null || handle_error "Android Studio preferences" "Could not backup preferences"
        fi

        # Backup Android SDK location (if exists)
        if [[ -f "$HOME/Library/Android/sdk/tools/source.properties" ]]; then
            echo "$HOME/Library/Android/sdk" > "$backup_dir/sdk_path.txt"
        elif [[ -d "$HOME/Android/sdk" ]]; then
            echo "$HOME/Android/sdk" > "$backup_dir/sdk_path.txt"
        fi

        # Backup gradle settings
        if [[ -f "$HOME/.gradle/gradle.properties" ]]; then
            cp "$HOME/.gradle/gradle.properties" "$backup_dir/" 2>/dev/null || handle_error "Gradle properties" "Could not backup gradle.properties"
        fi

        # Create list of installed SDK packages
        if [[ -d "$HOME/Library/Android/sdk" ]] && [[ -f "$HOME/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager" ]]; then
            "$HOME/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager" --list_installed > "$backup_dir/sdk_packages.txt" 2>/dev/null || true
        fi

        echo "✅ Android Studio configuration backed up"
    else
        echo "EXCLUDE_ANDROID_STUDIO:true" >> "$USER_PREFS"
    fi
}

android_studio_restore() {
    # Check if Android Studio should be restored
    if ! android_studio_should_restore; then
        return 0
    fi

    log "Restoring Android Studio configuration..."

    local backup_dir="$BACKUP_DIR/android_studio"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No Android Studio backup found, skipping..."
        return 0
    fi

    # Ensure Android Studio is installed
    if ! android_studio_detect; then
        echo "⚠️  Android Studio not installed, skipping configuration restore..."
        return 0
    fi

    # Restore settings
    if [[ -d "$backup_dir/settings" ]]; then
        mkdir -p "$HOME/Library/Application Support/Google/"
        cp -R "$backup_dir/settings/" "$HOME/Library/Application Support/Google/AndroidStudio/" 2>/dev/null || handle_error "Android Studio settings restore" "Could not restore settings"
    fi

    # Restore preferences
    if [[ -d "$backup_dir/preferences" ]]; then
        mkdir -p "$HOME/Library/Preferences/"
        cp -R "$backup_dir/preferences/" "$HOME/Library/Preferences/AndroidStudio/" 2>/dev/null || handle_error "Android Studio preferences restore" "Could not restore preferences"
    fi

    # Restore gradle properties
    if [[ -f "$backup_dir/gradle.properties" ]]; then
        mkdir -p "$HOME/.gradle"
        cp "$backup_dir/gradle.properties" "$HOME/.gradle/" || handle_error "Gradle properties restore" "Could not restore gradle.properties"
    fi

    echo "✅ Android Studio configuration restored"
    echo "⚠️  You may need to reconfigure SDK paths and download SDK packages"

    if [[ -f "$backup_dir/sdk_packages.txt" ]]; then
        echo "📋 SDK packages that were previously installed are listed in: $backup_dir/sdk_packages.txt"
    fi
}

android_studio_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_ANDROID_STUDIO:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file
        [ -d "$BACKUP_DIR/android_studio" ]
    fi
}
