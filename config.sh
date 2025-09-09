# Essential Applications Configuration
# This file lists the key applications to prioritize during backup and restore

# Core applications - ALWAYS backed up if present
CORE_CASKS=(
    "slack"
    "brave-browser"
    "arc"
    "intellij-idea"
    "goland"
    "rubymine"
    "webstorm"
    "pycharm"
    "clion"
    "datagrip"
    "phpstorm"
)

# Optional applications - ASK user if they want these backed up
OPTIONAL_CASKS=(
    "visual-studio-code"
    "docker"
    "postman"
    "figma"
    "spotify"
    "zoom"
    "1password"
    "alfred"
    "bartender-4"
    "cleanmymac"
    "istat-menus"
    "little-snitch"
    "rectangle"
    "timing"
    "notion"
    "discord"
    "telegram"
    "whatsapp"
    "dropbox"
    "google-drive"
    "firefox"
    "chrome"
)

# Essential CLI tools - ALWAYS backed up if present (no prompting)
ESSENTIAL_FORMULAS=(
    "git"
    "asdf"
    "mas"
    "curl"
    "wget"
    "jq"
    "tree"
    "htop"
    "bat"
    "exa"
    "ripgrep"
    "fd"
    "fzf"
    "tmux"
    "neovim"
    "gh"
)

# Optional CLI tools - ASK user if they want these backed up (only if installed)
OPTIONAL_FORMULAS=(
    "docker"
    "docker-compose"
    "kubectl"
    "terraform"
    "awscli"
    "gcloud"
    "yarn"
    "pnpm"
    "poetry"
    "pipenv"
    "hugo"
    "nginx"
    "redis"
    "postgresql"
    "mysql"
)

# ASDF Language Plugins - ALWAYS backed up if present
ASDF_LANGUAGES=(
    "nodejs"
    "python"
    "ruby"
    "golang"
    "java"
    "kotlin"
    "rust"
    "erlang"
    "elixir"
    "php"
    "terraform"
    "kubectl"
)

# App Store Applications - ALWAYS backed up if present
APP_STORE_APPS=(
    "Xcode"
    "TestFlight"
)
