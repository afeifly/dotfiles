#!/bin/bash

# Stop on any error
set -e

echo "🚀 Starting Dotfiles Installation..."

# 1. Detect OS
OS_TYPE="$(uname)"
echo "OS Detected: $OS_TYPE"

# 2. Install Homebrew if missing (The universal package manager)
if ! command -v brew &> /dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add brew to PATH for the current session
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# 3. Install Core Packages
echo "📦 Installing core packages via Homebrew..."
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
echo "🔗 Linking dotfiles with GNU Stow..."
cd "$HOME/dotfiles"

# Backup existing files to avoid stow conflicts
backup_if_exists() {
    if [ -f "$HOME/$1" ] && [ ! -L "$HOME/$1" ]; then
        echo "⚠️  Backing up existing $1 to $1.bak"
        mv "$HOME/$1" "$HOME/$1.bak"
    fi
}

backup_if_exists ".zshrc"
backup_if_exists ".tmux.conf"
backup_if_exists ".vimrc"

stow zsh tmux vim nvim git

# 7. Trigger Plugin Installations (Headless)
echo "✨ Finalizing plugin installation..."

# Neovim (Uses Lazy.nvim auto-bootstrap)
echo "  - Syncing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa

# Tmux (Installs plugins defined in .tmux.conf)
echo "  - Installing Tmux plugins..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

echo "✅ ALL DONE! Please restart your terminal or run: source ~/.zshrc"
