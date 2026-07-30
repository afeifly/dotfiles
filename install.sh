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
    $SUDO apt-get install -y git stow tmux ripgrep bat fzf zsh curl wget vim bc fd-find

    # Try installing extra tools for shell integration on Linux
    echo "📦 Attempting to install extra CLI tools on Linux..."
    $SUDO apt-get install -y zoxide eza starship yazi || true

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

    # Ubuntu specific: symlink 'fdfind' to 'fd'
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        echo "🔗 Symlinking fdfind to fd..."
        mkdir -p "$HOME/.local/bin"
        ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd" || true
    fi

    # Install lazygit on Linux if not present
    if ! command -v lazygit &> /dev/null; then
        echo "💾 Downloading Lazygit (stable)..."
        mkdir -p "$HOME/.local/bin"
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        if [ -z "$LAZYGIT_VERSION" ]; then
            LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
        fi
        curl -L "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -o lazygit.tar.gz
        tar xf lazygit.tar.gz lazygit
        mv lazygit "$HOME/.local/bin/lazygit"
        rm lazygit.tar.gz
    fi

elif [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "📦 Using Homebrew to install packages..."
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    # Install core tools + dependencies (including ghostty and relative apps)
    brew install git stow neovim vim tmux ripgrep bat fzf zsh terminal-notifier caarlos0/tap/timer \
                 starship zoxide yazi eza zsh-autosuggestions zsh-syntax-highlighting zsh-completions lazygit fd
    brew install --cask ghostty hammerspoon font-jetbrains-mono-nerd-font font-maple-mono-nf
    brew upgrade neovim vim || true
fi

# 3. Additional CLI Tools (Cross-Platform)
echo "🔍 Setting up latest fzf..."
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --bin --no-update-rc
else
    cd "$HOME/.fzf" && git pull && "./install" --bin --no-update-rc
    cd - > /dev/null
fi
# Ensure fzf binary is accessible
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"

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
rm -rf "$HOME/.config/ghostty"
rm -rf "$HOME/.config/yazi"
rm -f "$HOME/.config/starship.toml"
rm -f "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.fzf.zsh"
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.vimrc"
rm -f "$HOME/.zsh_ghostty"
rm -f "$HOME/.hammerspoon/init.lua"

# Clean up incorrect macOS Ghostty config file if it exists
rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

# Ensure parent directories exist
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.hammerspoon"

# Restow (R = restow)
stow -R zsh tmux vim nvim git ghostty starship hammerspoon yazi

# Create symlinks for lazyvim appname support (config and data)
ln -sf "$HOME/.config/nvim" "$HOME/.config/lazyvim"

# Ensure actual nvim directories exist before linking lazyvim to them
mkdir -p "$HOME/.local/share/nvim"
mkdir -p "$HOME/.local/state/nvim"
mkdir -p "$HOME/.cache/nvim"

# Link data directory so lazyvim finds the same plugins
rm -rf "$HOME/.local/share/lazyvim"
ln -sf "$HOME/.local/share/nvim" "$HOME/.local/share/lazyvim"

# Link state and cache directories to avoid stale data bugs
rm -rf "$HOME/.local/state/lazyvim"
ln -sf "$HOME/.local/state/nvim" "$HOME/.local/state/lazyvim"

rm -rf "$HOME/.cache/lazyvim"
ln -sf "$HOME/.cache/nvim" "$HOME/.cache/lazyvim"

# 6. Trigger Plugin Installations
echo "✨ Finalizing plugins..."
export PATH="$HOME/.local/bin:$PATH"

# Neovim: Sync plugins
echo "  - Syncing Neovim..."
# Use NVIM_APPNAME to match your 'vi' alias
NVIM_APPNAME=lazyvim nvim --headless "+Lazy! sync" +qa || true

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

# 7. Configure IDEs (VS Code, Cursor, Antigravity IDE) to use system clipboard in Vim mode
echo "⚙️ Configuring IDE Vim modes to use system clipboard..."
for settings_dir in \
    "$HOME/Library/Application Support/Code/User" \
    "$HOME/Library/Application Support/Cursor/User" \
    "$HOME/Library/Application Support/Antigravity IDE/User" \
    "$HOME/.config/Code/User" \
    "$HOME/.config/Cursor/User" \
    "$HOME/.config/Antigravity IDE/User"; do
    if [ -d "$settings_dir" ]; then
        settings_file="$settings_dir/settings.json"
        if [ ! -f "$settings_file" ]; then
            echo "{}" > "$settings_file"
        fi
        echo "  - Configuring $settings_file..."
        python3 -c "
import json
path = '$settings_file'
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}
data['vim.useSystemClipboard'] = True
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
" || true
    fi
done

echo "✅ ALL DONE! Run: source ~/.zshrc"
