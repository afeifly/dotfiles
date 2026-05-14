#!/bin/bash

# Stop on any error
set -e

# If running as root, we must force Homebrew to allow it
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Running as root. Forcing Homebrew root mode..."
    export HOMEBREW_ON_LINUX_FORCE_ROOT=1
    export NONINTERACTIVE=1
fi

echo "🚀 Starting Dotfiles Installation..."

# 1. Detect OS
OS_TYPE="$(uname)"
echo "OS Detected: $OS_TYPE"

# 2. Install Homebrew if missing
if ! command -v brew &> /dev/null; then
    if [[ "$OS_TYPE" == "Linux" ]]; then
        echo "📦 Installing Linux prerequisites..."
        apt-get update && apt-get install -y build-essential curl file git sudo
    fi

    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add brew to PATH for the current session
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# 3. Install Core Packages
echo "📦 Installing core packages..."
brew install git stow neovim tmux ripgrep bat fzf zsh

# 4. Prepare Oh My Zsh and Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "🔌 Cloning Zsh plugins..."
mkdir -p "$ZSH_CUSTOM/plugins"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ] && git clone https://github.com/jeffreytse/zsh-vi-mode "$ZSH_CUSTOM/plugins/zsh-vi-mode"

# 5. Prepare Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "🪟 Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 6. Use Stow to Symlink Configs
echo "🔗 Linking dotfiles..."
cd "$HOME/dotfiles"

# Backup existing files
backup_if_exists() {
    if [ -f "$HOME/$1" ] && [ ! -L "$HOME/$1" ]; then
        mv "$HOME/$1" "$HOME/$1.bak"
    fi
}

backup_if_exists ".zshrc"
backup_if_exists ".tmux.conf"
backup_if_exists ".vimrc"

stow zsh tmux vim nvim git

# 7. Trigger Plugin Installations
echo "✨ Finalizing plugins..."
nvim --headless "+Lazy! sync" +qa
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

echo "✅ ALL DONE! Run: source ~/.zshrc"
