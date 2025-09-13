# Docker container for testing Mac Rebuild
# Uses Ubuntu for glibc compatibility with Homebrew

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/testuser

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    sudo \
    wget \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    openssh-client \
    rsync \
    zip \
    unzip \
    jq \
    python3 \
    python3-pip \
    nodejs \
    npm \
    file \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install Ruby 3.4 from source (required for Homebrew)
RUN apt-get update && apt-get install -y \
    ruby-full \
    ruby-dev \
    && rm -rf /var/lib/apt/lists/*

# Create test user (similar to macOS user setup)
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy and set up entrypoint script early
COPY tests/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to test user and create minimal directory structure
USER testuser
WORKDIR /home/testuser

# Create essential directories only (simplified to avoid space issues)
RUN mkdir -p .ssh .config Applications Library/Preferences Library/Application\ Support

# Install Homebrew for the test user (optional, for more realistic testing)
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || echo "Homebrew installation failed, continuing without it"

# Add Homebrew to PATH if it was installed
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Copy mac-rebuild into container
COPY --chown=testuser:testuser . /opt/mac-rebuild
WORKDIR /opt/mac-rebuild

# Make mac-rebuild executable
RUN chmod +x mac-rebuild

# Set up PATH to include mac-rebuild
ENV PATH="/opt/mac-rebuild:$PATH"

# Create mock Time Machine backup directory for testing
RUN mkdir -p /tmp/mock-time-machine && \
    echo "Mock Time Machine backup for testing" > /tmp/mock-time-machine/backup.marker

# Set environment variables to enable test mode
ENV MAC_REBUILD_TEST_MODE=1
ENV MAC_REBUILD_NON_INTERACTIVE=1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
