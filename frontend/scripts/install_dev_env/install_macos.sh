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

if [[ "${installrust:-N}" == [Yy] ]]; then
   printMessage "Installing Rust."
   brew install rustup-init
   rustup-init -y --default-toolchain=stable

   source "$HOME/.cargo/env"
else
   printMessage "Skipping Rust installation."
fi

# Install sqllite
printMessage "Installing sqlLite3."
brew install sqlite3

printMessage "Setting up Flutter"

# Get the current Flutter version
FLUTTER_VERSION=$(flutter --version | grep -oE 'Flutter [^ ]+' | grep -oE '[^ ]+$')
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
flutter config --enable-macos-desktop

# Fix any problems reported by flutter doctor
flutter doctor

# Add the githooks directory to your git configuration
printMessage "Setting up githooks."
git config core.hooksPath .githooks

# Install go-gitlint
printMessage "Installing go-gitlint."
GOLINT_FILENAME="go-gitlint_1.1.0_osx_x86_64.tar.gz"
curl -L https://github.com/llorllale/go-gitlint/releases/download/1.1.0/${GOLINT_FILENAME} --output ${GOLINT_FILENAME}
tar -zxv --directory .githooks/. -f ${GOLINT_FILENAME} gitlint
rm ${GOLINT_FILENAME}

# Change to the frontend directory
cd frontend || exit 1

# Install cargo make
printMessage "Installing cargo-make."
cargo install --force cargo-make

# Install duckscript
printMessage "Installing duckscript."
cargo install --force duckscript_cli

# Check prerequisites
printMessage "Checking prerequisites."
cargo make appflowy-flutter-deps-tools