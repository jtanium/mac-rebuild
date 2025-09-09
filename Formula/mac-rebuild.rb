class MacRebuild < Formula
  desc "Intelligent Mac development environment backup and restore tool"
  homepage "https://github.com/jtanium/mac-rebuild"
  url "https://github.com/jtanium/mac-rebuild/archive/v1.0.0.tar.gz"
  sha256 "201c71c1a8a182ce66bf66766c2010ae5ce3cc3a70df3c4d703bd9cdbc41d9b1"
  license "MIT"

  depends_on "git"

  def install
    bin.install "mac-rebuild"
    prefix.install "lib"
    man1.install "man/mac-rebuild.1"
  end

  def caveats
    <<~EOS
      Mac Rebuild has been installed!

      ⚠️  IMPORTANT: Create a Time Machine backup before using this tool!

      Getting started:
        1. mac-rebuild --help          # View all available commands
        2. mac-rebuild backup          # Create backup with storage options
        3. mac-rebuild restore <path>  # Restore from backup

      Examples:
        # Create backup (interactive storage selection)
        mac-rebuild backup

        # Restore from iCloud Drive
        mac-rebuild restore ~/Library/Mobile\\ Documents/com~apple~CloudDocs/mac-backup

        # Restore from other cloud storage
        mac-rebuild restore ~/Dropbox/mac-backup
        mac-rebuild restore /Volumes/USB/mac-backup

      Fresh install workflow:
        1. Install Homebrew + mac-rebuild
        2. mac-rebuild restore <your-backup-path>
        3. All apps, SSH keys, and settings restored!
    EOS
  end

  test do
    system "#{bin}/mac-rebuild", "--version"
  end
end
