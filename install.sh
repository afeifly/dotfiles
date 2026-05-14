#!/bin/bash

# Stop on any error
set -e

echo "🚀 Starting Dotfiles Installation..."

# 1. Detect OS
OS_TYPE="$(uname)"
echo "OS Detected: $OS_TYPE"

# 2. Install Core Packages
if [[ "$OS_TYPE" == "Linux" ]]; then
    echo "📦 Using apt-get to install packages..."
    # Check if we need sudo
    SUDO=""
    if [ "$EUID" -ne 0 ]; then
        SUDO="sudo"
    fi
    
    $SUDO apt-get update
    $SUDO apt-get install -y git stow neovim tmux ripgrep bat fzf zsh curl

    # Ubuntu specific: symlink 'batcat' to 'bat' if it exists
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        echo "🔗 Symlinking batcat to bat..."
        mkdir -p "$HOME/.local/bin"
        ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
    fi

elif [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "📦 Using Homebrew to install packages..."
    if ! command -v brew &> /dev/null; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    brew install git stow neovim tmux ripgrep bat fzf zsh
fi

# 3. Prepare Oh My Zsh and Plugins
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

# 4. Prepare Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "🪟 Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 5. Use Stow to Symlink Configs
echo "🔗 Linking dotfiles..."
cd "$HOME/dotfiles"

backup_if_exists() {
    if [ -f "$HOME/$1" ] && [ ! -L "$HOME/$1" ]; then
        mv "$HOME/$1" "$HOME/$1.bak"
    fi
}

backup_if_exists ".zshrc"
backup_if_exists ".tmux.conf"
backup_if_exists ".vimrc"

stow zsh tmux vim nvim git

# 6. Trigger Plugin Installations
echo "✨ Finalizing plugins..."
# Force path for nvim if we just installed it to .local/bin or via apt
export PATH="$HOME/.local/bin:$PATH"

# Run nvim sync and tmux install
nvim --headless "+Lazy! sync" +qa
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

echo "✅ ALL DONE! Run: source ~/.zshrc"
