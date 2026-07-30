#!/bin/bash

# Path to the file we want to open
FILE_PATH="$1"

# Check if Neovim is running and has a saved socket path
if [ -f /tmp/nvim-current-server.pipe ]; then
    NVIM_SERVER=$(cat /tmp/nvim-current-server.pipe)

    # Check if the server socket is still active
    if [ -S "$NVIM_SERVER" ] || [[ "$OSTYPE" == "darwin"* && -e "$NVIM_SERVER" ]]; then
        # Open the file remotely
        # Convert path to absolute to avoid relative path resolution bugs in Neovim remote call
        ABS_PATH=$(realpath "$FILE_PATH")
        nvim --server "$NVIM_SERVER" --remote "$ABS_PATH"

        # Close the tmux popup
        tmux display-popup -C
        exit 0
    fi
fi

# Fallback: if Neovim is not running in background, edit inline in Yazi popup
nvim "$FILE_PATH"
