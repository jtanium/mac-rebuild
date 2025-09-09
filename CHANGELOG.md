# Changelog

All notable changes to Mac Rebuild will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-09-09

### Added
- **Enhanced ASDF Restoration**: Completely redesigned ASDF backup and restore functionality
  - **System Dependencies Management**: Automatically installs compilation dependencies for common languages (Node.js, Python, Ruby, Erlang, etc.)
  - **Plugin URL Backup**: Captures actual Git repository URLs for plugins to ensure proper restoration
  - **Detailed Version Tracking**: Backs up all installed versions per plugin, not just current versions
  - **Individual Tool Installation**: Installs each runtime individually with better error handling and recovery
  - **Fallback Strategies**: Attempts to install latest version if specific version fails
  - **Comprehensive Error Reporting**: Clear error messages and manual recovery instructions

### Improved
- **ASDF Plugin Installation**: Robust plugin installation with URL-based restoration and fallback mechanisms
- **Runtime Compilation**: Proper handling of compilation dependencies and long build times
- **Session Management**: Ensures ASDF is properly sourced in current shell session during restoration
- **Error Recovery**: Graceful degradation when some tools fail, with clear instructions for manual fixes
- **User Feedback**: Better progress indicators and time expectations for long-running operations

### Fixed
- **Plugin Installation Failures**: Resolved issues with plugins not installing due to missing URLs or dependencies
- **Runtime Compilation Errors**: Fixed missing system dependencies that caused runtime compilation to fail
- **Shell Environment Issues**: Proper ASDF environment setup in both current and future sessions

## [1.0.7] - 2025-09-09

### Added
- **Project Philosophy Documentation**: Added comprehensive "Why Mac Rebuild?" section to README
  - Explains the clean slate philosophy vs Time Machine's "restore everything" approach
  - Describes the digital cruft problem that accumulates over time
  - Added "Marie Kondo for your Mac" analogy for selective restoration
  - Emphasizes performance benefits of starting fresh without digital baggage

### Changed
- **Improved Documentation**: Enhanced README with clearer motivation and value proposition
- **Better User Onboarding**: Users now understand why Mac Rebuild exists before diving into technical details

## [1.0.6] - 2025-09-09

### Fixed
- **Cross-Platform Compatibility**: Fixed Intel vs Apple Silicon Mac compatibility issues
  - Backup script now dynamically detects Homebrew installation path (`/opt/homebrew` for Apple Silicon, `/usr/local` for Intel)
  - Restore script now correctly handles ASDF installation paths based on detected architecture
  - Eliminated hardcoded `/opt/homebrew` paths that caused "No such file or directory" errors on Intel Macs
  - Both backup and restore operations now work seamlessly across all Mac architectures

### Removed
- **Homebrew Formula**: Removed `Formula/mac-rebuild.rb` file to eliminate circular dependency
  - Formula file created chicken-and-egg problem where updating SHA hash would change the calculated SHA
  - Users should now install directly via repository cloning or installation scripts
  - Removes maintenance overhead of keeping SHA hashes in sync

### Changed
- **Architecture Detection**: Both scripts now display detected Homebrew prefix during startup for transparency
- **Error Prevention**: Improved reliability when running restore operations on different Mac architectures

## [1.0.0] - 2025-09-08

### Added
- Initial release of Mac Rebuild
- Interactive backup system with intelligent storage selection
- Support for iCloud Drive, cloud storage, and Git repository backups
- Automatic SSH key handling for fresh macOS installs
- Homebrew formula for easy installation
- Comprehensive restore functionality
- Bootstrap package creation for private repositories
- Man page documentation
- Multiple backup storage strategies

### Features
- **iCloud Drive Integration**: Seamless backup to iCloud with automatic sync
- **SSH Key Management**: Secure handling of SSH keys during backup/restore
- **Homebrew Integration**: Install via `brew install mac-rebuild`
- **Cross-Device Sync**: Backup available on all your Apple devices
- **Fresh Install Workflow**: Optimized for new Mac setup scenarios
- **Multiple Storage Options**: iCloud, Dropbox, Google Drive, Git repositories
- **Security First**: Automatic exclusion of sensitive data from public repos

[Unreleased]: https://github.com/jtanium/mac-rebuild/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/jtanium/mac-rebuild/compare/v1.0.7...v1.1.0
[1.0.7]: https://github.com/jtanium/mac-rebuild/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/jtanium/mac-rebuild/compare/v1.0.0...v1.0.6
[1.0.0]: https://github.com/jtanium/mac-rebuild/releases/tag/v1.0.0
