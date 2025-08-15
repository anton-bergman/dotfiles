#!/usr/bin/env bash

set -e

echo "Installing CLI tools..."

# Detect OS / package manager
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt >/dev/null; then
        sudo apt update
        sudo apt install -y fastfetch tlrc
    else
        echo "Unsupported Linux distro. Please install fastfetch and tldr manually."
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! command -v brew >/dev/null; then
        echo "Homebrew not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install fastfetch tlrc
else
    echo "Unsupported OS. Please install CLI tools manually."
    exit 1
fi

echo -e "\nAll CLI tools installed!"
