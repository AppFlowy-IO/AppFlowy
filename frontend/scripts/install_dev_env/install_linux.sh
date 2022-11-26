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

# Enable the flutter stable channel
printMessage "Setting up Flutter"
flutter channel stable

# Enable linux desktop
flutter config --enable-linux-desktop

# Fix any problems reported by flutter doctor
flutter doctor

# install keybinder-3.0
apt-get install keybinder-3.0

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
cargo make appflowy-deps-tools
