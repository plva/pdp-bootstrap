#!/bin/bash

# Check if Zsh is installed
if command -v zsh >/dev/null 2>&1; then
    echo "Zsh is installed."
    # Optionally, switch to Zsh here if needed
    # exec zsh
else
    echo "Zsh is not installed. Please install Zsh to proceed."
    exit 1
fi

