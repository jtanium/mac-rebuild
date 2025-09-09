class MacRebuild < Formula
  desc "Intelligent Mac development environment backup and restore tool"
  homepage "https://github.com/jtanium/mac-rebuild"
  url "https://github.com/jtanium/mac-rebuild/archive/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
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

      To get started:
        1. Run: mac-rebuild --help
        2. For first-time setup: mac-rebuild init
        3. To restore from backup: mac-rebuild restore <git-repo-url>

      Examples:
        mac-rebuild backup
        mac-rebuild restore https://github.com/jtanium/mac-backup.git
        mac-rebuild restore git@github.com:jtanium/mac-backup.git
    EOS
  end

  test do
    system "#{bin}/mac-rebuild", "--version"
  end
end
