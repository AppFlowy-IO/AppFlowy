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

# Install protoc plugin
printMessage "Install protoc plugin"
dart pub global activate protoc_plugin

# Add protoc to path
printMessage "Add protoc plugin to PATH"
echo "export PATH=${HOME}/.pub-cache/bin"

# Add the githooks directory to your git configuration
printMessage "Setting up githooks."
git config core.hooksPath .githooks

# Change to the frontend directory
cd frontend

# Install cargo make
printMessage "Installing cargo-make."
cargo install --force cargo-make

# Install duckscript
printMessage "Installing duckscript."
cargo install --force duckscript_cli

# Install CommitLint
printMessage "Installing CommitLint."
npm install @commitlint/cli @commitlint/config-conventional --save-dev

# Check prerequisites
printMessage "Checking prerequisites."
cargo make flowy_dev
