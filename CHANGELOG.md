# Changelog

All notable changes to Mac Rebuild will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/jtanium/mac-rebuild/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/jtanium/mac-rebuild/releases/tag/v1.0.0
