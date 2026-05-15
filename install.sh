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
    SUDO=""
    [ "$EUID" -ne 0 ] && SUDO="sudo"
    
    $SUDO apt-get update
    $SUDO apt-get install -y git stow tmux ripgrep bat fzf zsh curl wget vim bc

    # Fix: Use AppImage for Neovim to guarantee version >= 0.10
    if ! command -v nvim &> /dev/null || [[ "$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)" < "0.10" ]]; then
        echo "💾 Downloading Neovim AppImage (stable)..."
        mkdir -p "$HOME/.local/bin"
        # Using curl with progress bar and following redirects
        curl -L --fail --progress-bar "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage" -o "$HOME/.local/bin/nvim"
        chmod +x "$HOME/.local/bin/nvim"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Ubuntu specific: symlink 'batcat' to 'bat'
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        echo "🔗 Symlinking batcat to bat..."
        mkdir -p "$HOME/.local/bin"
        ln -sf /usr/bin/batcat "$HOME/.local/bin/bat" || true
    fi

elif [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "📦 Using Homebrew to install packages..."
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    # Install core tools + dependencies for 'work' function
    brew install git stow neovim vim tmux ripgrep bat fzf zsh terminal-notifier caarlos0/tap/timer
    brew upgrade neovim vim || true
fi

# 3. Additional CLI Tools (Cross-Platform)
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

# 4. Prepare Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "🪟 Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 5. Use Stow to Symlink Configs
echo "🔗 Linking dotfiles..."
cd "$HOME/dotfiles"

# Remove existing files/directories to avoid stow conflicts
echo "  - Removing existing configs to avoid conflicts..."
rm -rf "$HOME/.config/nvim"
rm -rf "$HOME/.config/lazyvim"
rm -rf "$HOME/.config/git"
rm -f "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.fzf.zsh"
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.vimrc"

# Ensure parent directories exist
mkdir -p "$HOME/.config"

# Restow (R = restow)
stow -R zsh tmux vim nvim git

# Create a symlink for lazyvim appname support
ln -sf "$HOME/.config/nvim" "$HOME/.config/lazyvim"

# 6. Trigger Plugin Installations
echo "✨ Finalizing plugins..."
export PATH="$HOME/.local/bin:$PATH"

# Neovim: Sync plugins
echo "  - Syncing Neovim..."
nvim --headless "+Lazy! sync" +qa

# Tmux: Install plugins
echo "  - Installing Tmux plugins..."
if [ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
    
    # 1. Start a temporary tmux server in the background
    tmux start-server
    # 2. Create a dummy session so tmux stays alive
    tmux new-session -d -s "temp_install"
    # 3. Explicitly source the new config
    tmux source-file "$HOME/.tmux.conf"
    # 4. Now run the installer
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    # 5. Clean up
    tmux kill-session -t "temp_install"
else
    echo "⚠️  TPM not found, skipping plugin installation."
fi

echo "✅ ALL DONE! Run: source ~/.zshrc"
