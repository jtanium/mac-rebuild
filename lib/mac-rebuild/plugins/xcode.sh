#!/bin/bash

# Xcode Plugin for Mac Rebuild
# Handles backup and restore of Xcode settings, preferences, and developer tools

# Plugin metadata
xcode_description() {
    echo "Manages Xcode IDE settings, preferences, and developer configurations"
}

xcode_priority() {
    echo "50"  # After other development tools
}

xcode_has_detection() {
    return 0
}

xcode_detect() {
    [[ -d "/Applications/Xcode.app" ]] || \
    [[ -d "/Applications/Xcode-beta.app" ]] || \
    command -v xcodebuild &> /dev/null
}

xcode_backup() {
    log "Checking for Xcode..."

    if ! xcode_detect; then
        echo "Xcode not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Xcode. Do you want to backup Xcode settings and preferences?" "y"; then
        echo "INCLUDE_XCODE:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/xcode"
        mkdir -p "$backup_dir"

        # Backup Xcode preferences
        if [[ -f "$HOME/Library/Preferences/com.apple.dt.Xcode.plist" ]]; then
            cp "$HOME/Library/Preferences/com.apple.dt.Xcode.plist" "$backup_dir/" 2>/dev/null || handle_error "Xcode preferences" "Could not backup preferences"
        fi

        # Backup Xcode user data
        if [[ -d "$HOME/Library/Developer/Xcode/UserData" ]]; then
            cp -R "$HOME/Library/Developer/Xcode/UserData/" "$backup_dir/UserData/" 2>/dev/null || handle_error "Xcode UserData" "Could not backup UserData"
        fi

        # Backup code snippets
        if [[ -d "$HOME/Library/Developer/Xcode/UserData/CodeSnippets" ]]; then
            mkdir -p "$backup_dir/UserData/"
            cp -R "$HOME/Library/Developer/Xcode/UserData/CodeSnippets/" "$backup_dir/UserData/CodeSnippets/" 2>/dev/null || handle_error "Xcode code snippets" "Could not backup code snippets"
        fi

        # Backup key bindings
        if [[ -d "$HOME/Library/Developer/Xcode/UserData/KeyBindings" ]]; then
            mkdir -p "$backup_dir/UserData/"
            cp -R "$HOME/Library/Developer/Xcode/UserData/KeyBindings/" "$backup_dir/UserData/KeyBindings/" 2>/dev/null || handle_error "Xcode key bindings" "Could not backup key bindings"
        fi

        # Backup themes
        if [[ -d "$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes" ]]; then
            mkdir -p "$backup_dir/UserData/"
            cp -R "$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes/" "$backup_dir/UserData/FontAndColorThemes/" 2>/dev/null || handle_error "Xcode themes" "Could not backup themes"
        fi

        # Backup breakpoints
        if [[ -f "$HOME/Library/Developer/Xcode/UserData/xcdebugger/Breakpoints_v2.xcbkptlist" ]]; then
            mkdir -p "$backup_dir/UserData/xcdebugger/"
            cp "$HOME/Library/Developer/Xcode/UserData/xcdebugger/Breakpoints_v2.xcbkptlist" "$backup_dir/UserData/xcdebugger/" 2>/dev/null || handle_error "Xcode breakpoints" "Could not backup breakpoints"
        fi

        # Backup simulator preferences
        if [[ -f "$HOME/Library/Preferences/com.apple.iphonesimulator.plist" ]]; then
            cp "$HOME/Library/Preferences/com.apple.iphonesimulator.plist" "$backup_dir/" 2>/dev/null || handle_error "iOS Simulator preferences" "Could not backup simulator preferences"
        fi

        # List installed simulators
        if command -v xcrun &> /dev/null; then
            xcrun simctl list runtimes > "$backup_dir/installed_simulators.txt" 2>/dev/null || handle_error "Simulator runtimes" "Could not list simulator runtimes"
        fi

        # Backup provisioning profiles
        if [[ -d "$HOME/Library/MobileDevice/Provisioning Profiles" ]]; then
            cp -R "$HOME/Library/MobileDevice/Provisioning Profiles/" "$backup_dir/ProvisioningProfiles/" 2>/dev/null || handle_error "Provisioning profiles" "Could not backup provisioning profiles"
        fi

        echo "✅ Xcode configuration backed up"
    else
        echo "EXCLUDE_XCODE:true" >> "$USER_PREFS"
    fi
}

xcode_restore() {
    # Check if Xcode should be restored
    if ! xcode_should_restore; then
        return 0
    fi

    log "Restoring Xcode configuration..."

    local backup_dir="$BACKUP_DIR/xcode"

    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No Xcode backup found, skipping..."
        return 0
    fi

    # Ensure Xcode is installed
    if ! xcode_detect; then
        echo "⚠️  Xcode not installed, skipping configuration restore..."
        return 0
    fi

    # Restore preferences
    if [[ -f "$backup_dir/com.apple.dt.Xcode.plist" ]]; then
        cp "$backup_dir/com.apple.dt.Xcode.plist" "$HOME/Library/Preferences/" || handle_error "Xcode preferences restore" "Could not restore preferences"
    fi

    # Restore UserData
    if [[ -d "$backup_dir/UserData" ]]; then
        mkdir -p "$HOME/Library/Developer/Xcode/"
        cp -R "$backup_dir/UserData/" "$HOME/Library/Developer/Xcode/UserData/" 2>/dev/null || handle_error "Xcode UserData restore" "Could not restore UserData"
    fi

    # Restore simulator preferences
    if [[ -f "$backup_dir/com.apple.iphonesimulator.plist" ]]; then
        cp "$backup_dir/com.apple.iphonesimulator.plist" "$HOME/Library/Preferences/" || handle_error "iOS Simulator preferences restore" "Could not restore simulator preferences"
    fi

    # Restore provisioning profiles
    if [[ -d "$backup_dir/ProvisioningProfiles" ]]; then
        mkdir -p "$HOME/Library/MobileDevice/"
        cp -R "$backup_dir/ProvisioningProfiles/" "$HOME/Library/MobileDevice/Provisioning Profiles/" 2>/dev/null || handle_error "Provisioning profiles restore" "Could not restore provisioning profiles"
    fi

    echo "✅ Xcode configuration restored"

    if [[ -f "$backup_dir/installed_simulators.txt" ]]; then
        echo "📋 Previously installed simulators are listed in: $backup_dir/installed_simulators.txt"
        echo "⚠️  You may need to reinstall simulator runtimes through Xcode preferences"
    fi

    echo "⚠️  You may need to re-sign in to your Apple Developer account"
}

xcode_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_XCODE:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file
        [ -d "$BACKUP_DIR/xcode" ]
    fi
}
