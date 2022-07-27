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


# Install Rust 
printMessage "The Rust programming language is required to compile AppFlowy."
printMessage "We can install it now if you don't already have it on your system."

read -p "$(printSuccess "Do you want to install Rust? [y/N]") " installrust

if [ ${installrust^^} == "Y" ]; then
   printMessage "Installing Rust."
   brew install rustup-init
   rustup-init -y --default-toolchain=stable
else
   printMessage "Skipping Rust installation."
fi

# Install sqllite
printMessage "Installing sqlLite3."
brew install sqlite3 

# Enable the flutter stable channel
printMessage "Setting up Flutter"
flutter channel stable

# Enable linux desktop
flutter config --enable-macos-desktop

# Fix any problems reported by flutter doctor
flutter doctor

# Add the githooks directory to your git configuration
printMessage "Setting up githooks."
git config core.hooksPath .githooks

# Install go-gitlint 
printMessage "Installing go-gitlint."
GOLINT_FILENAME="go-gitlint_1.1.0_osx_x86_64.tar.gz"
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
cargo make flowy_dev
