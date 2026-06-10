# --- ZSH Configuration (Cross-Platform) ---

# Global Environment
export TZ='Asia/Shanghai'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export ZSH="$HOME/.oh-my-zsh"

# 1. Detect Homebrew Path (Mac vs Linux)
if [[ -d "/opt/homebrew/bin" ]]; then
    BREW_PREFIX="/opt/homebrew"
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
export NVM_DIR="$HOME/.nvm"
# Check common nvm locations
NVM_SCRIPT=""
if [[ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ]]; then
    NVM_SCRIPT="$BREW_PREFIX/opt/nvm/nvm.sh"
    NVM_COMPLETION="$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    NVM_SCRIPT="$HOME/.nvm/nvm.sh"
fi

[[ -n "$NVM_SCRIPT" ]] && \. "$NVM_SCRIPT"
[[ -s "$NVM_COMPLETION" ]] && \. "$NVM_COMPLETION"

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
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS="--preview '(bat --style=numbers --color=always --line-range :500 {} || tree -C {}) 2> /dev/null'"

fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "rg --ignore-case --pretty --context 10 '$1' {}" | xargs -r vim
}

# 6. Local/Secrets
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# 7. ZSH Theme & Plugins
ZSH_THEME="ys"

plugins=(git wd docker docker-compose zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)
source $ZSH/oh-my-zsh.sh

# 8. SDKMAN (Standard location)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Added by Antigravity CLI installer
export PATH="/Users/ex/.local/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/ex/.antigravity-ide/antigravity-ide/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/Users/ex/.local/bin:$PATH"

# Load Ghostty terminal configurations on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -f ~/.zsh_ghostty ]] && source ~/.zsh_ghostty
fi
