class MacRebuild < Formula
  desc "Intelligent Mac development environment backup and restore tool"
  homepage "https://github.com/jtanium/mac-rebuild"
  url "https://github.com/jtanium/mac-rebuild/archive/refs/heads/main.tar.gz"
  version "1.0.3"
  sha256 "1e162d8eaa703f496bc01ef65d222a847c6e49576d6d4b5fbc4266ea8bef2b38"

  def install
    # Install the main script
    bin.install "mac-rebuild"

    # Install library files
    (libexec/"lib/mac-rebuild").install Dir["lib/mac-rebuild/*"]

    # Install man page
    man1.install "man/mac-rebuild.1" if File.exist?("man/mac-rebuild.1")

    # Make the main script executable
    chmod 0755, bin/"mac-rebuild"
  end

  test do
    system "#{bin}/mac-rebuild", "--version"
  end
end
