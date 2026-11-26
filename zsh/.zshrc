# --- ZSH Configuration (Cross-Platform) ---

# Global Environment
export TZ='Asia/Shanghai'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export ZSH="$HOME/.oh-my-zsh"

# 1. Detect Homebrew Path (Mac vs Linux)
if [[ -d "/opt/homebrew/bin" ]]; then
    BREW_PREFIX="/opt/homebrew"
elif [[ -d "/usr/local/bin" && -x "/usr/local/bin/brew" ]]; then
    BREW_PREFIX="/usr/local"
elif [[ -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
    BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

if [[ -n "$BREW_PREFIX" ]]; then
    export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
fi

# 2. Universal Paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/fvm/default/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# 3. NVM Configuration (Cross-Platform)
# Load the REAL nvm.sh with --no-use. Two traps otherwise:
#   - Homebrew's wrapper (/opt/homebrew/opt/nvm/nvm.sh) does not forward "$@",
#     so --no-use would be silently dropped.
#   - Without --no-use, nvm_auto resolves the default alias on every shell
#     start and costs ~0.7s. It is a no-op here anyway: the default alias is
#     the bare word "node" (not a version), so nvm never activates a version
#     and `nvm current` stays "system".
export NVM_DIR="$HOME/.nvm"
NVM_SCRIPT=""
if [[ -n "$BREW_PREFIX" && -s "$BREW_PREFIX/opt/nvm/libexec/nvm.sh" ]]; then
    NVM_SCRIPT="$BREW_PREFIX/opt/nvm/libexec/nvm.sh"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    NVM_SCRIPT="$HOME/.nvm/nvm.sh"
elif [[ -n "$BREW_PREFIX" && -s "$BREW_PREFIX/opt/nvm/nvm.sh" ]]; then
    NVM_SCRIPT="$BREW_PREFIX/opt/nvm/nvm.sh"   # wrapper: cannot pass --no-use
fi

[[ -n "$NVM_SCRIPT" ]] && \. "$NVM_SCRIPT" --no-use

# Completion is deferred until after oh-my-zsh (see step 7). nvm's completion
# script re-runs compinit itself if compinit is not yet loaded, which would add
# a third full compinit pass (~0.4s) to every shell start.
NVM_COMPLETION=""
[[ -n "$BREW_PREFIX" && -s "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]] && \
    NVM_COMPLETION="$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

# 4. Android SDK
export ANDROID_HOME="$BREW_PREFIX/share/android-commandlinetools"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# 5. Aliases & Functions
alias cl="clear"
alias vi="NVIM_APPNAME=lazyvim nvim"
alias vim="vim"
alias lvim="NVIM_APPNAME=lazyvim nvim"
alias python='python3'

if [[ "$OSTYPE" == "darwin"* ]]; then
  work() {
    timer "${1:-25m}" && osascript -e 'display notification "Pomodoro" with title "Work Timer Up!" sound name "Glass"'
  }
fi

# Cross-platform 'code' command
unalias code 2>/dev/null
if [[ "$OSTYPE" == "darwin"* ]]; then
    code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}
fi

# FZF Integration
# NOTE: sourced AFTER oh-my-zsh below — oh-my-zsh's lib/key-bindings.zsh binds
# '^r' to history-incremental-search-backward, and '^r'/'^R' are the same key
# (0x12), so loading fzf before it would leave Ctrl+R broken.
export FZF_DEFAULT_OPTS="--preview '(bat --style=numbers --color=always --line-range :500 {} || tree -C {}) 2> /dev/null'"

fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "rg --ignore-case --pretty --context 10 '$1' {}" | xargs -r vim
}

# 6. Local/Secrets
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# 7. ZSH Theme & Plugins
ZSH_THEME="ys"

# zsh-completions must be on fpath BEFORE oh-my-zsh runs compinit, otherwise
# its ~180 completion functions are never scanned. Moved here from
# ~/.zsh_ghostty so compinit only has to run once instead of three times.
# ($BREW_PREFIX is already resolved above; avoids ~5 `brew --prefix` subprocesses.)
if [[ -n "$BREW_PREFIX" && -d "$BREW_PREFIX/share/zsh-completions" ]]; then
    fpath=("$BREW_PREFIX/share/zsh-completions" $fpath)
fi

# zsh-autosuggestions / zsh-syntax-highlighting are loaded from Homebrew inside
# ~/.zsh_ghostty (after every other plugin, which zsh-syntax-highlighting
# requires). Only hand them to oh-my-zsh when that file will not run.
if [[ "$OSTYPE" == "darwin"* && -f "$HOME/.zsh_ghostty" ]]; then
    plugins=(git wd docker docker-compose zsh-vi-mode)
else
    plugins=(git wd docker docker-compose zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)
fi
source $ZSH/oh-my-zsh.sh

# fzf keybindings/complete — must follow oh-my-zsh so Ctrl+R stays fzf's
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# nvm's completion script re-runs compinit itself when compinit is not yet
# loaded, adding a third full pass (~0.4s). After oh-my-zsh, compinit already
# exists, so it skips straight to bashcompinit.
[[ -s "$NVM_COMPLETION" ]] && \. "$NVM_COMPLETION"

# 8. SDKMAN (Standard location)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Load Ghostty terminal configurations on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -f ~/.zsh_ghostty ]] && source ~/.zsh_ghostty
fi

# Antigravity & OpenCode CLI tools
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"
export PATH="$HOME/.ocv/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

export ANTHROPIC_BASE_URL="https://ai.exmm.top/antigravity"
export ANTHROPIC_AUTH_TOKEN="sk-d99585cd752326928146fea4cf8f57a679598b29c116f034802d03c4ef115ef7"
export ANTHROPIC_MODEL="gemini-3.5-flash[1M]"

alias docker="container"



