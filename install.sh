#!/bin/bash

# Stop on any error
set -e

# -----------------------------------------------------------------------------
# Usage:
#   ./install.sh              Symlink configs out of this repo (repo must stay).
#   ./install.sh --one-time   COPY configs into $HOME as regular files, so this
#                             repo can be deleted right after. Nothing in the
#                             copied configs references the repo path.
#   ./install.sh --help       Show this help.
# -----------------------------------------------------------------------------
ONE_TIME=0
for arg in "$@"; do
    case "$arg" in
        --one-time|--copy|--standalone)
            ONE_TIME=1
            ;;
        -h|--help)
            echo "Usage: $0 [--one-time]"
            echo "  (no args)    Symlink configs from this repo."
            echo "  --one-time   Copy configs into \$HOME; safe to delete the repo after."
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $arg" >&2
            echo "Usage: $0 [--one-time]" >&2
            exit 1
            ;;
    esac
done

echo "🚀 Starting Dotfiles Installation..."
if [ "$ONE_TIME" -eq 1 ]; then
    echo "🔒 One-time mode: configs will be COPIED (no symlinks back to this repo)."
fi

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

    # Fix: install Neovim >= 0.10 when missing or too old.
    # Two traps this avoids:
    #   - The old check used `[[ "$v" < "0.10" ]]`, a STRING compare.
    #     "0.7" < "0.10" is FALSE (chars '7' vs '1'), so apt's nvim 0.7.2
    #     was never replaced -> lazy.nvim (needs >= 0.8) refused to load
    #     -> `:Lazy` was never registered -> "E492: Not an editor command".
    #   - AppImage needs FUSE, which most VPS images lack. Use the tarball.
    nvim_lt() {
        # true if $1 < $2 ; GNU sort -V does numeric dotted comparison
        [ "$1" = "$2" ] && return 1
        [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
    }
    NVIM_MIN="0.10"
    cur_nvim=""
    command -v nvim &> /dev/null && cur_nvim="$(nvim --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
    if [ -z "$cur_nvim" ] || nvim_lt "$cur_nvim" "$NVIM_MIN"; then
        echo "💾 Installing Neovim >= $NVIM_MIN (tarball, no FUSE needed)..."
        mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
        case "$(uname -m)" in
            aarch64|arm64) NVIM_ARCH="arm64" ;;
            *)              NVIM_ARCH="x86_64" ;;
        esac
        NVIM_TARBALL="$HOME/.local/opt/nvim-linux-${NVIM_ARCH}.tar.gz"
        if curl -L --fail --progress-bar \
            "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
            -o "$NVIM_TARBALL"; then
            if tar -xzf "$NVIM_TARBALL" -C "$HOME/.local/opt"; then
                rm -f "$NVIM_TARBALL"
                # nvim resolves its runtime via /proc/self/exe, so a symlink
                # to bin/nvim still finds ../share/nvim/runtime correctly.
                ln -sf "$HOME/.local/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" "$HOME/.local/bin/nvim"
                export PATH="$HOME/.local/bin:$PATH"
                echo "  ✅ $(nvim --version 2>/dev/null | head -n1)"
            else
                rm -f "$NVIM_TARBALL"
                echo "  ⚠️  Failed to extract Neovim; keeping $(nvim --version 2>/dev/null | head -n1 || echo 'no nvim')"
            fi
        else
            rm -f "$NVIM_TARBALL" 2>/dev/null || true
            echo "  ⚠️  Neovim download failed; keeping $(nvim --version 2>/dev/null | head -n1 || echo 'no nvim')"
        fi
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
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
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

# 5. Use Stow to Symlink Configs (or COPY them in one-time mode)
if [ "$ONE_TIME" -eq 1 ]; then
    echo "🔗 Copying dotfiles into \$HOME..."
else
    echo "🔗 Linking dotfiles..."
fi
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

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

# Install packages (stow = symlinks; one-time mode = real copies)
PACKAGES=(zsh tmux vim nvim git ghostty starship hammerspoon)
for pkg in "${PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$pkg" ]; then
        if [ "$ONE_TIME" -eq 1 ]; then
            echo "  - Copying $pkg..."
            # cp -RL dereferences: hidden files (.zshrc, .zprofile) are kept,
            # no symlinks are created, and existing $HOME/.config content is
            # merged (not nested as .config/.config).
            cp -RL "$DOTFILES_DIR/$pkg/." "$HOME/"
        else
            echo "  - Stowing $pkg..."
            stow -d "$DOTFILES_DIR" -t "$HOME" -R "$pkg"
        fi
    fi
done

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
    tmux start-server || true
    # 2. Kill any leftover session from an earlier/interrupted run.
    #    Without this, `new-session` fails with "duplicate session" and —
    #    because the script runs under `set -e` — the whole install aborts.
    tmux kill-session -t "temp_install" 2>/dev/null || true
    # 3. Create a dummy session so tmux stays alive
    tmux new-session -d -s "temp_install" || true
    # 4. Explicitly source the new config
    tmux source-file "$HOME/.tmux.conf" || true
    # 5. Now run the installer
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    # 6. Clean up
    tmux kill-session -t "temp_install" 2>/dev/null || true
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

# 8. One-time mode: verify nothing points back at this repo
if [ "$ONE_TIME" -eq 1 ]; then
    echo "🔍 Verifying no config still references $DOTFILES_DIR ..."
    BAD=0
    # Scan the configs we just installed for the repo path
    CHECK=(.zshrc .zprofile .zsh_ghostty .fzf.zsh .tmux.conf .vimrc .config/nvim .config/git .config/ghostty .config/starship.toml .hammerspoon/init.lua)
    for item in "${CHECK[@]}"; do
        target="$HOME/$item"
        [ -e "$target" ] || continue
        if [ -L "$target" ]; then
            echo "  ⚠️  $item is still a symlink -> $(readlink "$target")"
            BAD=1
        fi
        if grep -qF "$DOTFILES_DIR" "$target" 2>/dev/null; then
            echo "  ⚠️  $item contains the repo path"
            BAD=1
        fi
    done
    if [ "$BAD" -eq 0 ]; then
        echo "  ✅ All configs are real files with no reference to the repo."
        echo "  🗑️  Safe to delete: $DOTFILES_DIR"
    else
        echo "  ❌ Some configs still depend on the repo — do NOT delete it yet."
        exit 1
    fi
fi

echo "✅ ALL DONE! Run: source ~/.zshrc"
