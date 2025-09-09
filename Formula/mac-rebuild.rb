class MacRebuild < Formula
  desc "Intelligent Mac development environment backup and restore tool"
  homepage "https://github.com/jtanium/mac-rebuild"
  url "https://github.com/jtanium/mac-rebuild/archive/refs/heads/main.tar.gz"
  version "1.0.4"
  sha256 "1d7ae65bce9f509314f2d0fd84dcb0bf8dd1bcfb8b7a5c051f1cf044acd51023"

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
