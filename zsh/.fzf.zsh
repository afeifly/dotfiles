# Setup fzf
# ---------
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# Use --zsh for newer fzf versions, fallback to example scripts for older ones
if fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
else
  # Fallback for older fzf versions (like 0.29 on Ubuntu via apt)
  [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
fi
