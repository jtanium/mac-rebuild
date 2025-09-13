# Mac Rebuild v2.0 - Intelligent Mac Development Environment Manager

A **modular, plugin-based** Mac development environment backup and restore tool that solves the SSH key authentication problem for fresh installs.

## 🎉 What's New in v2.0

**Major Architecture Overhaul!** Mac Rebuild v2.0 introduces a complete **modular plugin system** that makes it incredibly easy to extend and customize your backup/restore process.

### ✨ Key v2.0 Features
- **🔧 Modular Plugin Architecture**: Each component (Homebrew, ASDF, VS Code, JetBrains, etc.) is now an isolated plugin
- **🎯 Enhanced JetBrains Support**: Automatically detects and restores IDEs via Homebrew
- **⚡ Enhanced ASDF Plugin**: System dependencies, URL-based plugin backup, fallback strategies
- **📦 14 Core Plugins**: Ready-to-use plugins for all major development tools
- **🔍 Plugin Management**: `mac-rebuild plugins` command to see what's available
- **🚀 Simplified Interface**: Clean commands - no more complex flags
- **🔌 Easy Extensibility**: Add new tools by creating simple plugin files

### 🔄 Migration from v1.x
- **Fully backward compatible** - existing backups work perfectly
- **Simplified commands** - just `mac-rebuild backup` and `mac-rebuild restore <path>`
- **Enhanced features** - JetBrains IDEs now auto-install during restore

## 🎯 Why Mac Rebuild?

**The Clean Slate Problem:** Over time, your Mac accumulates digital cruft - old cache files, forgotten applications, outdated configurations, and system bloat that slows everything down. While Time Machine is excellent for disaster recovery, it restores *everything* - including all that accumulated junk you'd rather leave behind.

**Mac Rebuild's Philosophy:** Start fresh, restore smart. Instead of dragging forward years of digital baggage, Mac Rebuild lets you:

- ✨ **Clean slate setup** - Fresh macOS without the cruft
- 🎯 **Selective restoration** - Only restore what you actually need
- 🚀 **Performance boost** - Eliminate years of accumulated system bloat
- 🧹 **Digital decluttering** - Perfect opportunity to audit your setup
- ⚡ **Faster machine** - Like getting a new Mac without buying one

Think of it as "Marie Kondo for your Mac" - if a setting or app doesn't spark joy (or productivity), leave it in the past.

## 📦 Installation

### Install via Homebrew (Recommended)

```bash
# Method 1: Using tap (recommended)
brew tap jtanium/mac-rebuild
brew install mac-rebuild

# Method 2: Direct tap installation
brew install jtanium/mac-rebuild/mac-rebuild
```

### Alternative Installation (If Above Fails)

If you encounter authentication issues:

```bash
# Force HTTPS and retry
git config --global url."https://github.com/".insteadOf git@github.com:
brew tap jtanium/mac-rebuild
brew install mac-rebuild
```

### Verify Installation
```bash
mac-rebuild --version    # Should show "Mac Rebuild v2.0.0"
mac-rebuild plugins      # Should show 8 core plugins
mac-rebuild --help       # Should mention modular plugin-based architecture
```

## ⚠️ IMPORTANT SAFETY WARNING

**🛡️ ALWAYS CREATE A TIME MACHINE BACKUP FIRST!**

Before using Mac Rebuild, **you must create a full Time Machine backup** of your system:

1. **Connect external drive** (USB, Thunderbolt, or network)
2. **System Settings → General → Time Machine → Add Backup Disk**
3. **Wait for initial backup to complete** (may take hours)
4. **Verify backup completed successfully**

### 🚨 Data Loss Risk Disclaimer

**Mac Rebuild is provided "AS IS" without warranty.** While designed to be safe:

- **YOU are responsible** for backing up your data
- **Restoration operations** can overwrite existing files
- **Always test** on a non-critical machine first
- **Time Machine** is your safety net for full system recovery

**By using this tool, you acknowledge:**
- You have created a complete Time Machine backup
- You understand the risk of data loss
- You accept full responsibility for any data loss
- You will not hold the authors liable for any damages

### 🔄 Recovery Options if Something Goes Wrong

1. **Time Machine:** Full system restore from Time Machine
2. **Manual recovery:** Restore individual files from Time Machine
3. **iCloud/Cloud backups:** Your personal files should be safe
4. **Re-download apps:** Most apps can be re-downloaded

---

## 🔐 The SSH Key Problem (Solved!)

**The Challenge:** After a fresh macOS install, you can't authenticate to private Git repositories because:
- No SSH keys exist yet
- SSH keys can't be stored in public repositories
- 1Password/authentication apps aren't installed yet

**Our Solution:** Use iCloud Drive + intelligent backup options.

## 🚀 Fresh Install Workflows

### Option A: iCloud Drive (Recommended ⭐)
**Best for:** Maximum convenience and security with SSH keys
```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install mac-rebuild  
brew install jtanium/mac-rebuild/mac-rebuild

# 3. Wait for iCloud to sync, then restore
mac-rebuild restore ~/Library/Mobile\ Documents/com~apple~CloudDocs/mac-backup
```

**Why iCloud is Perfect:**
- ✅ Already authenticated after fresh macOS install
- ✅ Automatically syncs across all your devices
- ✅ Secure (encrypted in transit and at rest)
- ✅ No manual file copying needed
- ✅ SSH keys stored safely and privately

### Option B: Other Cloud Storage
**Best for:** If you prefer Dropbox/Google Drive
```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install mac-rebuild
brew install jtanium/mac-rebuild/mac-rebuild

# 3. Restore from cloud storage
mac-rebuild restore ~/Dropbox/mac-backup
mac-rebuild restore ~/Google\ Drive/mac-backup
```

### Option C: Public Repository (Simplest)
**Best for:** Quick setup, don't mind public backup (SSH keys excluded automatically)
```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install mac-rebuild
brew install jtanium/mac-rebuild/mac-rebuild

# 3. Restore from public GitHub repo (no SSH needed)
mac-rebuild restore https://github.com/yourusername/mac-backup.git
```

### Option D: Private Repository + Bootstrap (Most Secure)
**Best for:** Private repos with full automation
```bash
# 1. Install Homebrew  
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install mac-rebuild
brew install jtanium/mac-rebuild/mac-rebuild

# 3. Use bootstrap package (from USB/secure storage)
cd bootstrap && mac-rebuild restore --bootstrap
```

## 📋 Before You Wipe Your Machine

Create a backup using the intelligent storage selector:

```bash
mac-rebuild backup
```

You'll be guided through storage options with **iCloud as the top recommendation**:

### 1. 📱 iCloud Drive (Recommended)
```
🔐 Storage Options for Your Backup:

1. 📱 iCloud Drive (Recommended - Already authenticated!)
   - Store in: ~/Library/Mobile Documents/com~apple~CloudDocs/
   - Pros: Auto-sync, already authenticated, secure, works immediately
   - Cons: Requires iCloud storage space

Choose storage approach [1-4]: 1
✅ Using iCloud Drive: ~/Library/Mobile Documents/com~apple~CloudDocs/mac-backup
```

### 2. 📂 Other Cloud Storage
```
Choose storage approach [1-4]: 2
Enter backup directory path: ~/Dropbox/mac-backup
```

### 3. 🌐 Public Repository
```
Choose storage approach [1-4]: 3
⚠️  Using public repository - SSH keys will be EXCLUDED automatically
Enter public repository URL (https://): https://github.com/yourusername/mac-backup.git
```

### 4. 🔒 Private Repository + Bootstrap
```
Choose storage approach [1-4]: 4
📋 Creating bootstrap package for private repository access...
```

## 🧠 Why iCloud is the Perfect Solution

### iCloud Drive Advantages:
1. **Already Authenticated:** No login required after fresh install
2. **Automatic Sync:** Files appear as soon as macOS is configured
3. **Cross-Device:** Available on all your Apple devices
4. **Secure:** Apple's encryption protects your SSH keys
5. **No Size Limits:** For typical backup sizes (few MB)
6. **Built-in:** No additional app installation needed

### Fresh Install Timeline with iCloud:
```
Fresh macOS Install
        ↓
Sign into Apple ID (required for macOS setup)
        ↓
iCloud Drive syncs automatically
        ↓
Install Homebrew + mac-rebuild
        ↓
Restore from iCloud (SSH keys included!)
        ↓
Fully configured in minutes
```

## 💡 Real-World iCloud Examples

**Your Typical Workflow:**
```bash
# Before wipe
mac-rebuild backup  # Choose option 1 (iCloud)
# → Backup saved to ~/Library/Mobile Documents/com~apple~CloudDocs/mac-backup

# After fresh install (during macOS setup, sign into Apple ID)
# iCloud automatically syncs your backup

# Then just 3 commands:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install jtanium/mac-rebuild/mac-rebuild
mac-rebuild restore ~/Library/Mobile\ Documents/com~apple~CloudDocs/mac-backup

# Everything restored: JetBrains IDEs, SSH keys, Slack, Brave, VS Code, etc.
```

**Enterprise/Work Machine:**
```bash
# If work prohibits iCloud, fall back to:
mac-rebuild backup  # Choose option 2, save to USB drive
# After fresh install:
mac-rebuild restore /Volumes/USB/mac-backup
```

## 🔒 Security with iCloud

- **End-to-End Encryption:** iCloud Advanced Data Protection encrypts your SSH keys
- **Apple ID Protected:** Requires your Apple credentials to access
- **Local Encryption:** macOS encrypts data before sending to iCloud
- **No GitHub Issues:** No public repository concerns

## 📋 Available Plugins

Mac Rebuild v2.0 includes these core plugins out of the box:

| Plugin | Priority | Description |
|--------|----------|-------------|
| **homebrew** | 10 | Manages Homebrew packages, casks, and taps |
| **asdf** | 20 | Enhanced ASDF support with system dependencies |
| **applications** | 30 | App Store applications and application inventories |
| **docker** | 35 | Docker Desktop settings, containers, images, and volumes |
| **vscode** | 40 | Visual Studio Code settings, extensions, and keybindings |
| **jetbrains** | 45 | JetBrains IDE configurations, settings, and applications |
| **tableplus** | 45 | TablePlus database connections, themes, and preferences |
| **chrome** | 50 | Google Chrome bookmarks, extensions, and preferences |
| **brave** | 51 | Brave Browser bookmarks, Brave Rewards, and settings |
| **arc** | 52 | Arc Browser spaces, sidebar configuration, and bookmarks |
| **vivaldi** | 53 | Vivaldi Browser workspaces, notes, and UI customizations |
| **opera** | 54 | Opera Browser workspaces, speed dial, and sidebar messengers |
| **firefox** | 55 | Firefox Browser bookmarks, extensions, and preferences |
| **safari** | 56 | Safari Browser bookmarks, reading list, and preferences |
| **dotfiles** | 60 | Important dotfiles and configuration files |
| **ssh** | 70 | SSH keys and configuration (handle with care) |
```bash
mac-rebuild plugins
```

Example output:
```
📦 homebrew (priority: 10) [enabled]
     Manages Homebrew packages, casks, and taps

📦 asdf (priority: 20) [enabled]  
     Manages ASDF version manager with enhanced plugin and runtime handling

📦 jetbrains (priority: 45) [enabled]
     Manages JetBrains IDE configurations, settings, and applications
```

## 🔧 Plugin Development Guide

### Creating Your First Plugin

Want to add support for a new tool? Creating a plugin is simple! Here's how:

#### 1. Create the Plugin File

```bash
# Create your plugin file
touch lib/mac-rebuild/plugins/my_tool.sh
chmod +x lib/mac-rebuild/plugins/my_tool.sh
```

#### 2. Basic Plugin Structure

```bash
#!/bin/bash

# My Tool Plugin for Mac Rebuild
# Add description of what your plugin does

# Plugin metadata (required)
my_tool_description() {
    echo "Manages My Tool configuration and settings"
}

my_tool_priority() {
    echo "30"  # Lower numbers execute first (10=high, 50=medium, 90=low)
}

# Detection (optional but recommended)
my_tool_detect() {
    # Return 0 if tool is installed, 1 if not
    command -v my_tool &> /dev/null
}

# Backup function (required)
my_tool_backup() {
    log "Backing up My Tool configuration..."
    
    # Check if tool is installed
    if ! my_tool_detect; then
        echo "⚠️  My Tool not found, skipping..."
        return 0
    fi
    
    # Ask user if they want to backup this tool
    if ask_yes_no "Found My Tool. Do you want to backup its configuration?" "y"; then
        echo "INCLUDE_MY_TOOL:true" >> "$USER_PREFS"
        
        local backup_dir="$BACKUP_DIR/my_tool"
        mkdir -p "$backup_dir"
        
        # Your backup logic here
        cp "$HOME/.my_tool_config" "$backup_dir/" || handle_error "My Tool backup" "Could not backup config"
        
        echo "✅ My Tool configuration backed up"
    else
        echo "EXCLUDE_MY_TOOL:true" >> "$USER_PREFS"
    fi
}

# Restore function (required)  
my_tool_restore() {
    # Check if this tool should be restored
    if ! my_tool_should_restore; then
        return 0
    fi
    
    log "Restoring My Tool configuration..."
    
    local backup_dir="$BACKUP_DIR/my_tool"
    
    if [ ! -d "$backup_dir" ]; then
        echo "⚠️  No My Tool backup found, skipping..."
        return 0
    fi
    
    # Install the tool if needed (via Homebrew)
    if ! my_tool_detect; then
        if command -v brew &> /dev/null; then
            brew install my-tool || handle_error "My Tool installation" "Could not install via Homebrew"
        fi
    fi
    
    # Restore configuration
    cp "$backup_dir/.my_tool_config" "$HOME/" || handle_error "My Tool restore" "Could not restore config"
    
    echo "✅ My Tool configuration restored"
}

# Helper function to check if restore should happen
my_tool_should_restore() {
    if [ -f "$USER_PREFS" ]; then
        grep -q "INCLUDE_MY_TOOL:true" "$USER_PREFS" 2>/dev/null
    else
        # Default to true if no preferences file but backup exists
        [ -d "$BACKUP_DIR/my_tool" ]
    fi
}
```

#### 3. Plugin Function Reference

**Required Functions:**
- `{plugin}_description()` - Brief description of what the plugin manages
- `{plugin}_backup()` - Backup logic for your tool
- `{plugin}_restore()` - Restore logic for your tool

**Optional Functions:**
- `{plugin}_priority()` - Execution order (default: 50)
- `{plugin}_detect()` - Check if tool is installed
- `{plugin}_init()` - Plugin initialization
- `{plugin}_should_restore()` - Conditional restore logic

**Available Utilities:**
- `log "message"` - Green progress message
- `warn "message"` - Yellow warning message  
- `error "message"` - Red error message
- `ask_yes_no "question" "default"` - Interactive prompt
- `handle_error "context" "message"` - Error handling that continues execution

**Available Variables:**
- `$BACKUP_DIR` - Base backup directory
- `$USER_PREFS` - User preferences file
- `$HOME` - User home directory

#### 4. Plugin Best Practices

**Error Handling:**
```bash
# Always use error handling for critical operations
cp "$source" "$dest" || handle_error "Plugin name" "Specific error message"

# Check tool availability before using
if command -v my_tool &> /dev/null; then
    my_tool --export > "$backup_dir/export.json"
fi
```

**User Interaction:**
```bash
# Ask before backing up potentially sensitive data
if ask_yes_no "Backup My Tool API keys?" "n"; then
    # Backup sensitive data
fi
```

**Homebrew Integration:**
```bash
# Standard pattern for installing tools via Homebrew
if ! command -v my_tool &> /dev/null; then
    if command -v brew &> /dev/null; then
        brew install my-tool || handle_error "Installation" "Could not install my-tool"
    fi
fi
```

#### 5. Advanced Plugin Examples

**Application + Settings Plugin (like JetBrains):**
```bash
my_ide_backup() {
    # 1. Detect installed applications
    # 2. Map applications to Homebrew casks  
    # 3. Save application list for restoration
    # 4. Backup application settings
}

my_ide_restore() {
    # 1. Install applications via Homebrew
    # 2. Restore application settings
}
```

**Version Manager Plugin (like ASDF):**
```bash
my_version_manager_backup() {
    # 1. Backup tool lists
    # 2. Backup current versions
    # 3. Backup configuration files
}

my_version_manager_restore() {
    # 1. Install version manager
    # 2. Install system dependencies
    # 3. Install tools and versions
}
```

#### 6. Testing Your Plugin

```bash
# Test plugin loading
mac-rebuild plugins

# Test backup (dry run recommended)
mac-rebuild backup

# Test restore
mac-rebuild restore /path/to/test/backup
```

#### 7. Contributing Your Plugin

1. **Test thoroughly** on a non-critical machine
2. **Document any dependencies** or special requirements
3. **Follow naming conventions** (`tool_name.sh`)
4. **Submit a pull request** with your plugin

### 🎯 Plugin Ideas for Community

Here are some plugin ideas the community could contribute:

- **Docker**: Container images, volumes, networks
- **Kubernetes**: Contexts, configs, helm charts  
- **AWS CLI**: Profiles, configurations, credentials
- **Terraform**: State files, provider configs
- **Database Tools**: PostgreSQL, MySQL, Redis configs
- **Design Tools**: Figma, Sketch preferences
- **Communication**: Slack workspaces, Discord settings
- **Browsers**: Chrome/Firefox bookmarks, extensions
- **Terminal**: iTerm2, Warp, or Hyper configurations
- **Security**: 1Password, Bitwarden configurations
- **Note Taking**: Obsidian, Notion, Bear settings

## 🚀 What Gets Restored Automatically

With Mac Rebuild v2.0's plugin system, here's what gets automatically detected, backed up, and restored:

### 🍺 Development Tools
- **Homebrew**: All packages, casks, and taps
- **ASDF**: Version managers with system dependencies (Node.js, Python, Ruby, Go, etc.)
- **Git**: Global configuration and credentials

### 💻 IDEs & Editors  
- **JetBrains IDEs**: Auto-detects and installs IntelliJ, GoLand, PyCharm, WebStorm, CLion, etc.
- **VS Code**: Settings, extensions, keybindings, and themes
- **IDE Settings**: All your customizations, themes, and preferences

### 📱 Applications
- **App Store Apps**: List of installed applications (manual install required)
- **Homebrew Casks**: Automatic installation of GUI applications

### ⚙️ Configuration  
- **Dotfiles**: `.zshrc`, `.gitconfig`, `.npmrc`, and other config files
- **SSH Keys**: Secure backup and restore (with user consent)
- **Shell Configuration**: Terminal setup and aliases

## 📊 Commands Reference

```bash
# Create a backup
mac-rebuild backup

# Restore from backup
mac-rebuild restore <path>

# List available plugins
mac-rebuild plugins

# Check status
mac-rebuild status

# Show version
mac-rebuild --version

# Show help
mac-rebuild --help
```

## 🤝 Contributing

Mac Rebuild v2.0's modular architecture makes contributing easy! You can:

1. **Create plugins** for new tools and applications
2. **Improve existing plugins** with better detection or features
3. **Submit bug reports** and feature requests
4. **Improve documentation** and examples

See the [Plugin Development Guide](#plugin-development-guide) above for detailed instructions.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for developers who value clean, fast development environments
- Inspired by the need to solve the SSH key authentication problem
- Thanks to the Homebrew community for making package management simple
- Special thanks to contributors who help extend the plugin ecosystem

---

**Ready to rebuild your Mac the smart way?** Start with `mac-rebuild backup` and experience the future of Mac development environment management! 🚀
