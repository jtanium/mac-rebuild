#!/bin/bash

# Homebrew Plugin for Mac Rebuild
# Handles backup and restore of Homebrew packages, casks, and taps

# Plugin metadata
homebrew_description() {
    echo "Manages Homebrew packages, casks, and taps"
}

homebrew_priority() {
    echo "10"  # High priority - needed early for other tools
}

homebrew_init() {
    # Detect Homebrew installation path
    if [[ $(uname -m) == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
}

homebrew_has_detection() {
    return 0
}

homebrew_detect() {
    command -v brew &> /dev/null
}

homebrew_backup() {
    log "Backing up Homebrew packages..."

    if ! homebrew_detect; then
        echo "⚠️  Homebrew not found, skipping..."
        return 0
    fi

    local backup_dir="$BACKUP_DIR/homebrew"
    mkdir -p "$backup_dir"

    # Backup formulas, casks, and taps
    brew list --formula > "$backup_dir/formulas.txt" 2>/dev/null || handle_error "Homebrew formulas" "Could not list formulas"
    brew list --cask > "$backup_dir/casks.txt" 2>/dev/null || handle_error "Homebrew casks" "Could not list casks"
    brew tap > "$backup_dir/taps.txt" 2>/dev/null || handle_error "Homebrew taps" "Could not list taps"

    # Handle optional packages
    homebrew_handle_optional_packages

    echo "✅ Homebrew packages backed up"
}

homebrew_handle_optional_packages() {
    if [ -z "${OPTIONAL_CASKS:-}" ] && [ -z "${OPTIONAL_FORMULAS:-}" ]; then
        return 0
    fi

    echo ""
    log "Detecting optional applications..."

    # Handle optional casks
    if [ -n "${OPTIONAL_CASKS:-}" ]; then
        for cask in "${OPTIONAL_CASKS[@]}"; do
            if homebrew_is_installed "$cask"; then
                app_name=$(echo "$cask" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')
                if ask_yes_no "Found $app_name. Include in backup?"; then
                    echo "INCLUDE_CASK:$cask" >> "$USER_PREFS"
                else
                    echo "EXCLUDE_CASK:$cask" >> "$USER_PREFS"
                fi
            fi
        done
    fi

    # Handle optional formulas
    if [ -n "${OPTIONAL_FORMULAS:-}" ]; then
        echo ""
        for formula in "${OPTIONAL_FORMULAS[@]}"; do
            if homebrew_is_installed "$formula"; then
                if ask_yes_no "Found $formula CLI tool. Include in backup?"; then
                    echo "INCLUDE_FORMULA:$formula" >> "$USER_PREFS"
                else
                    echo "EXCLUDE_FORMULA:$formula" >> "$USER_PREFS"
                fi
            fi
        done
    fi
}

homebrew_restore() {
    log "Installing and restoring Homebrew..."

    # Install Homebrew if not present
    if ! homebrew_detect; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session
        echo "eval \"$(${HOMEBREW_PREFIX}/bin/brew shellenv)\"" >> ~/.zprofile
        eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
        echo "✅ Homebrew installed"
    else
        echo "✅ Homebrew already installed"
    fi

    # Restore taps first
    homebrew_restore_taps

    # Restore formulas
    homebrew_restore_formulas

    # Restore casks
    homebrew_restore_casks
}

homebrew_restore_taps() {
    log "Restoring Homebrew taps..."
    local taps_file="$BACKUP_DIR/homebrew/taps.txt"

    if [ -f "$taps_file" ]; then
        while IFS= read -r tap; do
            if [ -n "$tap" ]; then
                brew tap "$tap" || handle_error "Homebrew tap" "Could not add tap: $tap"
            fi
        done < "$taps_file"
        echo "✅ Homebrew taps restored"
    fi
}

homebrew_restore_formulas() {
    log "Restoring Homebrew formulas..."
    local formulas_file="$BACKUP_DIR/homebrew/formulas.txt"

    if [ -f "$formulas_file" ]; then
        while IFS= read -r formula; do
            if [ -n "$formula" ]; then
                # Check if this is an optional formula that user excluded
                if homebrew_is_excluded "FORMULA" "$formula"; then
                    echo "⏭️  Skipping $formula (excluded by user)"
                    continue
                fi

                brew install "$formula" || handle_error "Homebrew formula" "Could not install: $formula"
            fi
        done < "$formulas_file"
        echo "✅ Homebrew formulas restored"
    fi
}

homebrew_restore_casks() {
    log "Restoring Homebrew casks..."
    local casks_file="$BACKUP_DIR/homebrew/casks.txt"

    if [ -f "$casks_file" ]; then
        while IFS= read -r cask; do
            if [ -n "$cask" ]; then
                # Check if this is an optional cask that user excluded
                if homebrew_is_excluded "CASK" "$cask"; then
                    echo "⏭️  Skipping $cask (excluded by user)"
                    continue
                fi

                brew install --cask "$cask" || handle_error "Homebrew cask" "Could not install: $cask"
            fi
        done < "$casks_file"
        echo "✅ Homebrew casks restored"
    fi
}

# Helper functions
homebrew_is_installed() {
    brew list "$1" &>/dev/null
}

homebrew_is_excluded() {
    local type="$1"
    local item="$2"

    if [ -f "$USER_PREFS" ]; then
        grep -q "EXCLUDE_${type}:${item}" "$USER_PREFS" 2>/dev/null
    else
        return 1
    fi
}
