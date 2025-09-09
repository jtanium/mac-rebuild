# Mac Rebuild - Homebrew Package

An intelligent Mac development environment backup and restore tool that solves the SSH key authentication problem for fresh installs.

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
brew install mac-rebuild

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
brew install mac-rebuild

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
brew install mac-rebuild

# 3. Restore from public GitHub repo (no SSH needed)
mac-rebuild restore https://github.com/yourusername/mac-backup.git
```

### Option D: Private Repository + Bootstrap (Most Secure)
**Best for:** Private repos with full automation
```bash
# 1. Install Homebrew  
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install mac-rebuild
brew install mac-rebuild

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
brew install mac-rebuild
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

## 🎯 Perfect for Your Use Case

Since you're on macOS and likely already use Apple ID:
1. **No authentication hassle** - iCloud just works
2. **SSH keys safely stored** - encrypted and private
3. **Immediate availability** - syncs during macOS setup
4. **Zero manual steps** - no USB drives or file copying
5. **All your apps restored** - JetBrains, Slack, Brave, etc.

This eliminates the SSH key chicken-and-egg problem completely while being the most convenient option!
