# Contributing to Mac Rebuild

Thank you for your interest in contributing to Mac Rebuild! This project helps Mac users backup and restore their development environments seamlessly.

## How to Contribute

### Reporting Issues
- Check existing issues first to avoid duplicates
- Use the issue templates when available
- Include your macOS version and Mac Rebuild version
- Provide clear steps to reproduce any bugs

### Suggesting Features
- Open an issue with the "enhancement" label
- Describe the use case and why it would be valuable
- Consider if it fits the project's scope (Mac development environment backup/restore)

### Code Contributions
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test on a real Mac environment
5. Update documentation if needed
6. Submit a pull request

### Testing
- Test backup and restore operations on different macOS versions
- Verify Homebrew formula works correctly
- Test with different cloud storage scenarios (iCloud, Dropbox, etc.)

### Code Style
- Follow existing Bash script conventions
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small

## Development Setup

```bash
git clone https://github.com/jtanium/mac-rebuild.git
cd mac-rebuild
# Test locally
./mac-rebuild --help
```

## Questions?

Feel free to open an issue for any questions about contributing!
