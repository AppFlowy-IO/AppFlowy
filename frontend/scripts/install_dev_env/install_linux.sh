#!/bin/bash

YELLOW="\e[93m"
GREEN="\e[32m"
RED="\e[31m"
ENDCOLOR="\e[0m"

printMessage() {
    printf "${YELLOW}AppFlowy : $1${ENDCOLOR}\n"
}

printSuccess() {
    printf "${GREEN}AppFlowy : $1${ENDCOLOR}\n"
}

printError() {
    printf "${RED}AppFlowy : $1${ENDCOLOR}\n"
}

# Note: This script does not install applications which are installed by the package manager. There are too many package managers out there.

# Install Rust
printMessage "The Rust programming language is required to compile AppFlowy."
printMessage "We can install it now if you don't already have it on your system."

read -p "$(printSuccess "Do you want to install Rust? [y/N]") " installrust

if [ ${installrust^^} == "Y" ]; then
    printMessage "Installing Rust."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
    rustup toolchain install stable
    rustup default stable
else
    printMessage "Skipping Rust installation."
fi

printMessage "Setting up Flutter"
# Get the current Flutter version
FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K\S+')
# Check if the current version is 3.19.0
if [ "$FLUTTER_VERSION" = "3.19.0" ]; then
    echo "Flutter version is already 3.19.0"
else
    # Get the path to the Flutter SDK
    FLUTTER_PATH=$(which flutter)
    FLUTTER_PATH=${FLUTTER_PATH%/bin/flutter}

    current_dir=$(pwd)

    cd $FLUTTER_PATH
    # Use git to checkout version 3.19.0 of Flutter
    git checkout 3.19.0
    # Get back to current working directory
    cd "$current_dir"

    echo "Switched to Flutter version 3.19.0"
fi

# Enable linux desktop
flutter config --enable-linux-desktop

# Fix any problems reported by flutter doctor
flutter doctor

printMessage "Installing keybinder-3.0"
if command apt-get &>/dev/null; then
    sudo apt-get install keybinder-3.0-dev
elif command dnf &>/dev/null; then
    sudo dnf install keybinder3-devel
else
    echo 'Your system is not supported, please install keybinder3 manually.'
fi

printMessage "Installing libnotify"
if command apt-get &>/dev/null; then
    sudo apt-get install libnotify-dev
elif command dnf &>/dev/null; then
    sudo dnf install libnotify-dev
else
    echo 'Your system is not supported, please install libnotify-dev manually.'
fi

# For Video Block support
printMessage "Installing libmpv-dev"
if command apt-get &>/dev/null; then
    sudo apt-get install libmpv-dev
elif command dnf &>/dev/null; then
    sudo dnf install libmpv-dev
else
    echo 'Your system is not supported, please install libmpv-dev manually.'
fi

# Add the githooks directory to your git configuration
printMessage "Setting up githooks."
git config core.hooksPath .githooks

# Install go-gitlint
printMessage "Installing go-gitlint."
GOLINT_FILENAME="go-gitlint_1.1.0_linux_x86_64.tar.gz"
wget https://github.com/llorllale/go-gitlint/releases/download/1.1.0/${GOLINT_FILENAME}
tar -zxv --directory .githooks/. -f ${GOLINT_FILENAME} gitlint
rm ${GOLINT_FILENAME}

# Change to the frontend directory
cd frontend

# Install cargo make
printMessage "Installing cargo-make."
cargo install --force cargo-make

# Install duckscript
printMessage "Installing duckscript."
cargo install --force duckscript_cli

# Check prerequisites
printMessage "Checking prerequisites."
cargo make appflowy-flutter-deps-tools
