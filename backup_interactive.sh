#!/bin/bash

# Interactive Mac Rebuild Backup Script
# Run this script BEFORE wiping your machine to backup your current configuration

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Load configuration
source "$SCRIPT_DIR/config.sh"

echo "🚀 Starting interactive Mac backup process..."
echo "Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"/{homebrew,asdf,apps,dotfiles,system_preferences,ssh_keys,vscode,jetbrains}

# Function to log progress
log() {
    echo "📋 $1"
}

# Function to handle errors
handle_error() {
    echo "❌ Error in $1: $2"
    echo "Continuing with backup..."
}

# Function to ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local response

    if [[ "$default" == "y" ]]; then
        echo -n "$question [Y/n]: "
    else
        echo -n "$question [y/N]: "
    fi

    read -r response
    response=${response:-$default}
    [[ "$response" =~ ^[Yy]$ ]]
}

# Function to check if a Homebrew package is installed
is_brew_installed() {
    brew list "$1" &>/dev/null
}

# Function to check if an application exists
app_exists() {
    [[ -d "/Applications/$1.app" ]] || [[ -d "/Applications/Utilities/$1.app" ]]
}

# Function to check if VS Code is installed (any variant)
vscode_exists() {
    [[ -d "/Applications/Visual Studio Code.app" ]] || \
    [[ -d "/Applications/Visual Studio Code - Insiders.app" ]] || \
    [[ -d "/Applications/VSCodium.app" ]] || \
    is_brew_installed "visual-studio-code"
}

# Detect system information
log "Detecting system configuration..."
echo "macOS Version: $(sw_vers -productVersion)"
echo "Computer Name: $(scutil --get ComputerName)"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew not installed. Installing it first would make backup more complete."
    if ask_yes_no "Would you like to install Homebrew now?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Create user preferences file
USER_PREFS="$BACKUP_DIR/user_preferences.txt"
echo "# User preferences for restore" > "$USER_PREFS"
echo "# Generated on $(date)" >> "$USER_PREFS"

# Backup standard Homebrew packages
log "Backing up Homebrew packages..."
if command -v brew &> /dev/null; then
    brew list --formula > "$BACKUP_DIR/homebrew/formulas.txt" 2>/dev/null || handle_error "Homebrew formulas" "Could not list formulas"
    brew list --cask > "$BACKUP_DIR/homebrew/casks.txt" 2>/dev/null || handle_error "Homebrew casks" "Could not list casks"
    brew tap > "$BACKUP_DIR/homebrew/taps.txt" 2>/dev/null || handle_error "Homebrew taps" "Could not list taps"
    echo "✅ Homebrew packages backed up"

    # Detect and ask about optional casks
    echo ""
    log "Detecting optional applications..."
    for cask in "${OPTIONAL_CASKS[@]}"; do
        if is_brew_installed "$cask"; then
            app_name=$(echo "$cask" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')
            if ask_yes_no "Found $app_name. Include in backup?"; then
                echo "INCLUDE_CASK:$cask" >> "$USER_PREFS"
            else
                echo "EXCLUDE_CASK:$cask" >> "$USER_PREFS"
            fi
        fi
    done

    # Detect and ask about optional formulas
    echo ""
    for formula in "${OPTIONAL_FORMULAS[@]}"; do
        if is_brew_installed "$formula"; then
            if ask_yes_no "Found $formula CLI tool. Include in backup?"; then
                echo "INCLUDE_FORMULA:$formula" >> "$USER_PREFS"
            else
                echo "EXCLUDE_FORMULA:$formula" >> "$USER_PREFS"
            fi
        fi
    done
else
    echo "⚠️  Homebrew not found, skipping..."
fi

# Check for VS Code specifically and handle it specially
echo ""
log "Checking for VS Code..."
if vscode_exists; then
    if ask_yes_no "Found Visual Studio Code. Do you want to backup VS Code settings and extensions?" "y"; then
        echo "INCLUDE_VSCODE:true" >> "$USER_PREFS"

        # Backup VS Code configuration
        VSCODE_USER_DIR=""
        if [[ -d "$HOME/Library/Application Support/Code/User" ]]; then
            VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
        elif [[ -d "$HOME/Library/Application Support/Code - Insiders/User" ]]; then
            VSCODE_USER_DIR="$HOME/Library/Application Support/Code - Insiders/User"
        fi

        if [[ -n "$VSCODE_USER_DIR" ]]; then
            mkdir -p "$BACKUP_DIR/vscode"
            cp "$VSCODE_USER_DIR/settings.json" "$BACKUP_DIR/vscode/" 2>/dev/null || handle_error "VS Code settings" "Could not copy settings.json"
            cp "$VSCODE_USER_DIR/keybindings.json" "$BACKUP_DIR/vscode/" 2>/dev/null || handle_error "VS Code keybindings" "Could not copy keybindings.json"

            if command -v code &> /dev/null; then
                code --list-extensions > "$BACKUP_DIR/vscode/extensions.txt" 2>/dev/null || handle_error "VS Code extensions" "Could not list extensions"
            fi
            echo "✅ VS Code configuration backed up"
        fi
    else
        echo "EXCLUDE_VSCODE:true" >> "$USER_PREFS"
    fi
else
    echo "VS Code not found, skipping..."
fi

# Backup ASDF tools and versions
echo ""
log "Backing up ASDF tools and versions..."
if command -v asdf &> /dev/null; then
    asdf current > "$BACKUP_DIR/asdf/current_versions.txt" 2>/dev/null || handle_error "ASDF current" "Could not get current versions"
    asdf plugin list > "$BACKUP_DIR/asdf/plugins.txt" 2>/dev/null || handle_error "ASDF plugins" "Could not list plugins"

    # Backup .tool-versions if it exists
    if [ -f "$HOME/.tool-versions" ]; then
        cp "$HOME/.tool-versions" "$BACKUP_DIR/asdf/" || handle_error "ASDF tool-versions" "Could not copy .tool-versions"
    fi
    echo "✅ ASDF configuration backed up"
else
    echo "⚠️  ASDF not found, skipping..."
fi

# Backup App Store applications
echo ""
log "Backing up App Store applications..."
if command -v mas &> /dev/null; then
    mas list > "$BACKUP_DIR/apps/app_store_apps.txt" 2>/dev/null || handle_error "App Store apps" "Could not list App Store apps"
    echo "✅ App Store apps backed up"
else
    echo "⚠️  mas (Mac App Store CLI) not found, skipping App Store backup..."
    echo "   Install with: brew install mas"
fi

# Backup manually installed applications
log "Backing up list of installed applications..."
ls /Applications > "$BACKUP_DIR/apps/applications.txt" 2>/dev/null || handle_error "Applications" "Could not list applications"
ls /Applications/Utilities > "$BACKUP_DIR/apps/utilities.txt" 2>/dev/null || handle_error "Utilities" "Could not list utilities"

# Backup important dotfiles
echo ""
log "Backing up dotfiles and configurations..."
DOTFILES=(
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

for file in "${DOTFILES[@]}"; do
    if [ -f "$HOME/$file" ]; then
        mkdir -p "$BACKUP_DIR/dotfiles/$(dirname "$file")"
        cp "$HOME/$file" "$BACKUP_DIR/dotfiles/$file" 2>/dev/null || handle_error "Dotfile $file" "Could not copy $file"
    fi
done

# Backup SSH keys (be careful with these!)
echo ""
log "Backing up SSH keys..."
if [ -d "$HOME/.ssh" ]; then
    if ask_yes_no "Found SSH keys. Include in backup? (Handle with care!)" "y"; then
        cp -r "$HOME/.ssh" "$BACKUP_DIR/ssh_keys/" 2>/dev/null || handle_error "SSH keys" "Could not copy SSH directory"
        echo "✅ SSH keys backed up (handle with care!)"
        echo "INCLUDE_SSH:true" >> "$USER_PREFS"
    else
        echo "SSH keys excluded from backup"
        echo "EXCLUDE_SSH:true" >> "$USER_PREFS"
    fi
else
    echo "⚠️  No SSH directory found"
fi

# Backup JetBrains IDE settings
echo ""
log "Backing up JetBrains IDE configurations..."
JETBRAINS_DIRS=(
    "IntelliJIdea*"
    "GoLand*"
    "RubyMine*"
    "WebStorm*"
    "PyCharm*"
    "CLion*"
    "PhpStorm*"
    "DataGrip*"
)

jetbrains_found=false
for pattern in "${JETBRAINS_DIRS[@]}"; do
    for dir in "$HOME/Library/Application Support/JetBrains"/$pattern; do
        if [ -d "$dir" ]; then
            jetbrains_found=true
            break 2
        fi
    done
done

if $jetbrains_found; then
    if ask_yes_no "Found JetBrains IDE configurations. Include in backup?" "y"; then
        for pattern in "${JETBRAINS_DIRS[@]}"; do
            for dir in "$HOME/Library/Application Support/JetBrains"/$pattern; do
                if [ -d "$dir" ]; then
                    ide_name=$(basename "$dir")
                    mkdir -p "$BACKUP_DIR/jetbrains/$ide_name"

                    # Backup key configuration files
                    for config_dir in options keymaps colors; do
                        if [ -d "$dir/$config_dir" ]; then
                            cp -r "$dir/$config_dir" "$BACKUP_DIR/jetbrains/$ide_name/" 2>/dev/null || true
                        fi
                    done
                fi
            done
        done
        echo "✅ JetBrains IDE configurations backed up"
        echo "INCLUDE_JETBRAINS:true" >> "$USER_PREFS"
    else
        echo "EXCLUDE_JETBRAINS:true" >> "$USER_PREFS"
    fi
else
    echo "No JetBrains IDEs found"
fi

# Backup system preferences
echo ""
if ask_yes_no "Backup system preferences (Dock, Finder, etc.)?"; then
    log "Backing up system preferences..."
    defaults read > "$BACKUP_DIR/system_preferences/all_defaults.plist" 2>/dev/null || handle_error "System preferences" "Could not export defaults"
    echo "INCLUDE_SYSTEM_PREFS:true" >> "$USER_PREFS"
else
    echo "EXCLUDE_SYSTEM_PREFS:true" >> "$USER_PREFS"
fi

# Create a summary report
log "Creating backup summary..."
cat > "$BACKUP_DIR/backup_summary.txt" << EOF
Interactive Mac Backup Summary
==============================
Backup Date: $(date)
macOS Version: $(sw_vers -productVersion)
Computer Name: $(scutil --get ComputerName)

Homebrew Formulas: $(wc -l < "$BACKUP_DIR/homebrew/formulas.txt" 2>/dev/null || echo "0") packages
Homebrew Casks: $(wc -l < "$BACKUP_DIR/homebrew/casks.txt" 2>/dev/null || echo "0") applications
Applications: $(wc -l < "$BACKUP_DIR/apps/applications.txt" 2>/dev/null || echo "0") total apps

Backup Location: $BACKUP_DIR
User Preferences: $USER_PREFS

Next Steps:
1. Store this backup in a safe location (cloud storage, external drive)
2. After fresh install, run the restore script
3. The restore script will read your preferences and only restore what you selected
EOF

echo ""
echo "🎉 Interactive backup completed successfully!"
echo "📁 Backup location: $BACKUP_DIR"
echo "📄 Summary: $BACKUP_DIR/backup_summary.txt"
echo "⚙️  Preferences: $USER_PREFS"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
if grep -q "INCLUDE_SSH:true" "$USER_PREFS" 2>/dev/null; then
    echo "   - SSH keys have been backed up - handle with care!"
fi
echo "   - Review backup contents before storing in cloud"
echo "   - Consider encrypting sensitive backup data"
echo ""
echo "Next: Store this backup safely and run restore.sh after fresh install"
