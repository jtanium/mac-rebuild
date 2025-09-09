# Mac Rebuild v2.0 - Intelligent Mac Development Environment Manager

A **modular, plugin-based** Mac development environment backup and restore tool that solves the SSH key authentication problem for fresh installs.

## 🎉 What's New in v2.0

**Major Architecture Overhaul!** Mac Rebuild v2.0 introduces a complete **modular plugin system** that makes it incredibly easy to extend and customize your backup/restore process.

### ✨ Key v2.0 Features
- **🔧 Modular Plugin Architecture**: Each component (Homebrew, ASDF, VS Code, JetBrains, etc.) is now an isolated plugin
- **🎯 Enhanced JetBrains Support**: Automatically detects and restores IDEs via Homebrew
- **⚡ Enhanced ASDF Plugin**: System dependencies, URL-based plugin backup, fallback strategies
- **📦 7 Core Plugins**: Ready-to-use plugins for all major development tools
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
# Method 1: Direct formula installation (most reliable)
brew install https://raw.githubusercontent.com/jtanium/mac-rebuild/main/Formula/mac-rebuild.rb

# Method 2: Using tap (now with correct repository name)
brew tap jtanium/mac-rebuild
brew install mac-rebuild
```

### Alternative Installation (If Above Fails)

If you encounter authentication issues:

```bash
# Force HTTPS and retry
git config --global url."https://github.com/".insteadOf git@github.com:
brew install https://raw.githubusercontent.com/jtanium/mac-rebuild/main/Formula/mac-rebuild.rb
```

### Verify Installation
```bash
mac-rebuild --version
mac-rebuild --help
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
