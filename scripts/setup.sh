#!/bin/zsh

# Check if not running on macOS
if [[ "$OSTYPE" != darwin* ]]; then
    echo "Not running on macOS. This script is intended only for macOS."
    exit 1
fi

echo "Checking for Homebrew"
# Check if Homebrew is not installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# Check if Node.js is already installed
if command -v node >/dev/null 2>&1; then
    echo "Node.js is already installed."
else
    # Ask user for confirmation to install Node.js
    echo "Node.js is not installed. Install it using Homebrew? (y/n)"
    read -q user_confirm
    echo
    if [[ $user_confirm =~ ^[Yy]$ ]]; then
        echo "Installing Node.js and npm using Homebrew..."
        brew install node
    else
        echo "Installation of Node.js and npm aborted by user."
        exit 1
    fi
fi

# Verify installation of Node.js
if ! command -v node >/dev/null 2>&1; then
    echo "Installation of Node.js failed."
    exit 1
fi

# Check if npm is already installed
if ! command -v npm >/dev/null 2>&1; then
    echo "npm was not installed successfully."
    exit 1
fi

echo "Node.js and npm are successfully installed."
