# Changelog

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
