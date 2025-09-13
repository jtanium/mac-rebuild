# Changelog

## [v2.4.1] - 2025-09-12

### Added
-

### Changed
-

### Fixed
-

## [v2.4.0] - 2025-09-12

### Added
- **1Password Plugin**: Comprehensive backup and restore support for 1Password password manager
  - Backs up 1Password app settings, preferences, and group containers
  - Preserves application containers and preference files
  - Secure handling with vault data exclusion for security reasons
  - Automatic 1Password installation via Homebrew during restore
  - Supports both 1Password 7 and newer versions
- **Android Studio Plugin**: Complete development environment backup for Android Studio
  - Backs up Android Studio IDE settings, preferences, and project configurations
  - Preserves SDK configurations and gradle settings
  - Creates inventory of installed SDK packages for reference
  - Supports Android SDK path detection and backup
  - Automatic Android Studio installation via Homebrew during restore
- **Postman Plugin**: API development tool backup and restore support
  - Backs up Postman settings, collections, and environments
  - Preserves application support data and preferences
  - Handles local collections while noting cloud-synced collections
  - Automatic Postman installation via Homebrew during restore
- **Sublime Text Plugin**: Text editor configuration backup for Sublime Text
  - Supports both Sublime Text 3 and Sublime Text 4
  - Backs up user settings, Package Control configurations, and code snippets
  - Preserves custom themes, key bindings, and license information
  - Package Control automatic package installation on restore
  - Automatic Sublime Text installation via Homebrew during restore
- **Xcode Plugin**: Complete iOS/macOS development environment backup
  - Backs up Xcode IDE settings, preferences, and developer configurations
  - Preserves user data, code snippets, key bindings, and custom themes
  - Handles breakpoints, simulator preferences, and provisioning profiles
  - Creates inventory of installed simulator runtimes for reference
  - Comprehensive coverage of all Xcode user customizations

### Changed
- Updated plugin count in README from 14 to 19 core plugins
- Enhanced plugin priority system to accommodate new development tools

### Fixed
-

## [v2.3.0] - 2025-09-12

### Added
- Browser plugins for common browsers

### Changed
-

### Fixed
-

## [v2.2.8] - 2025-09-11

### Added
- **Docker Desktop Plugin**: Comprehensive backup and restore support for Docker Desktop
  - Backs up Docker Desktop settings, preferences, and daemon configuration
  - Interactive backup of containers, images, and volumes with selective options
  - Automatic detection of Docker Desktop installation (app bundle, Homebrew, or CLI)
  - Volume data preservation using tar archives
  - Docker network configuration backup for manual recreation
  - Automatic search and backup of docker-compose files
  - Smart installation during restore via Homebrew if Docker Desktop is missing
  - Graceful handling when Docker daemon is not running
  - **⚠️  TESTING NEEDED**: This plugin requires thorough testing with various Docker setups
- **TablePlus Plugin**: Complete backup and restore support for TablePlus database tool
  - Backs up encrypted database connections and credentials
  - Preserves custom themes, preferences, and window layouts
  - Supports custom queries/snippets and license information
  - Automatic TablePlus installation via Homebrew during restore
  - Secure handling of sensitive database connection data
- **Browser Plugins Suite**: Individual plugins for major web browsers
  - **Chrome Plugin**: Bookmarks, extensions, preferences, login data, and history
  - **Brave Plugin**: Bookmarks, Brave Rewards, Shields settings, and user data
  - **Arc Plugin**: Spaces, sidebar configuration, bookmarks, and Arc-specific features
  - **Vivaldi Plugin**: Workspaces, notes, UI customizations, and themes
  - **Opera Plugin**: Workspaces, speed dial, sidebar messengers, and preferences
  - **Firefox Plugin**: Bookmarks, extensions, preferences, form history, and login data
  - **Safari Plugin**: Bookmarks, reading list, top sites, and browser preferences
  - All browser plugins support selective backup of sensitive data (passwords, history, cookies)
  - Automatic browser installation via Homebrew during restore (except Safari - built into macOS)
  - Smart detection of running browsers with graceful closure prompts

### Changed
-

### Fixed
-

## [v2.2.7] - 2025-09-11

### Added
-

### Changed
-

### Fixed
-

## [v2.2.6] - 2025-09-11

### Added
-

### Changed
-

### Fixed
-

## [v2.2.5] - 2025-09-11

### Added
-

### Changed
-

### Fixed
-

## [v2.2.4] - 2025-09-11

### Added
-

### Changed
-

### Fixed
- More OMZ fixes

## [v2.2.3] - 2025-09-11

### Added
-

### Changed
-

### Fixed
- Fixing issues with Oh My Zsh restore

## [v2.2.2] - 2025-09-10

### Added
-

### Changed
-

### Fixed
- Fixed issue with restore not loading plugins

## [v2.2.1] - 2025-09-10

### Added
-

### Changed
-

### Fixed
- Fixed bug with Oh My Zsh not fully restored

## [v2.2.0] - 2025-09-09

### Added
Custom Fonts plugin
iTerm plugin

### Changed
-

### Fixed
-

All notable changes to Mac Rebuild will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-12-19

### 🎉 Major Architecture Overhaul - Modular Plugin System

This is a **major breaking release** that completely transforms Mac Rebuild from a monolithic script into a modern, extensible, plugin-based system.

### Added
- **🔧 Modular Plugin Architecture**: Complete rewrite with extensible plugin system
- **📦 7 Core Plugins**: Homebrew, ASDF, VS Code, JetBrains, Applications, Dotfiles, SSH
- **🎯 Enhanced JetBrains Support**: Automatic IDE detection and restoration via Homebrew
  - Detects installed IDEs (IntelliJ, GoLand, PyCharm, WebStorm, CLion, etc.)
  - Maps IDEs to Homebrew casks for automatic restoration
  - Restores both applications AND settings intelligently
- **⚡ Enhanced ASDF Plugin**: 
  - URL-based plugin backup for reliable restoration
  - System dependency installation (Python, Ruby, Node.js, etc.)
  - Fallback version installation strategies
  - Better error handling and recovery
- **🔍 Plugin Management**: `mac-rebuild plugins` command to list and manage plugins
- **📋 Priority-based Execution**: Plugins execute in optimal order automatically
- **🛡️ Better Error Isolation**: Plugin failures don't crash entire restore process
- **🔧 Plugin Development Guide**: Complete documentation for creating custom plugins

### Changed
- **🚀 BREAKING: Simplified Interface**: Removed `--modular` flags - plugin system is now default
- **📱 Streamlined Commands**: Clean `mac-rebuild backup` and `mac-rebuild restore <path>` interface
- **⚡ Enhanced Performance**: Parallel plugin execution where possible
- **🎨 Improved Output**: Better progress tracking and status reporting
- **📖 Updated Documentation**: Comprehensive plugin development guide

### Removed
- **📦 Legacy Monolithic Mode**: Removed dual-mode complexity for cleaner architecture
- **🚫 Deprecated Flags**: No more `--modular` flag needed

### Technical Details
- **🏗️ Plugin System**: Each component (Homebrew, ASDF, etc.) is now an isolated plugin
- **🔄 Execution Flow**: `backup` → `plugin_backup()` for each enabled plugin
- **⚙️ Configuration**: Plugin preferences saved in `enabled_plugins.txt`
- **🔌 Extensibility**: Add new tools by dropping plugin files in `lib/mac-rebuild/plugins/`
- **🛠️ Compatibility**: Works with macOS default bash (3.2.57+)

### Migration Guide
- **v1.x users**: Simply upgrade and run `mac-rebuild backup` (no flags needed)
- **Existing backups**: Fully compatible with v1.x backup format
- **New features**: JetBrains IDEs now auto-install during restore

## [1.1.0] - 2024-11-15

### Added
- Enhanced ASDF support with better plugin handling
- Improved error handling for missing tools
- System dependency installation for ASDF plugins

### Fixed
- ASDF plugin installation reliability
- Better fallback strategies for version installation

### Changed
- Improved backup progress reporting
- Enhanced restore process logging

## [1.0.0] - 2024-10-01

### Added
- Initial release of Mac Rebuild
- Interactive backup and restore system
- Support for Homebrew packages and casks
- ASDF version manager support
- VS Code settings and extensions backup
- SSH key management with security prompts
- Multiple storage options (iCloud, cloud storage, repositories)
- Time Machine safety checks
- Comprehensive documentation

### Features
- Intelligent storage selection with iCloud Drive recommendation
- SSH key chicken-and-egg problem solved
- Interactive prompts for security-sensitive data
- Cross-platform cloud storage support
- Bootstrap package creation for private repositories
