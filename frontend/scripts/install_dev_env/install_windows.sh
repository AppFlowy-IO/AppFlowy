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
if ! rustc --version; then

   printMessage "The Rust programming language is required to compile AppFlowy."
   printMessage "It has not been detected on your system."

   read -p "$(printSuccess "Do you want to install Rust? [y/N]") " installrust

   if [ ${installrust^^} == "Y" ]; then
      printMessage "Installing Rust."
      if ! curl --proto '=https' --tlsv1.2 -sSf https://win.rustup.rs/x86_64 -o rustup-init.exe; then
         printError "Failed to download the Rust installer"
         exit 1
      fi
      start "Rust Installer" rustup-init.exe
      read -p "$(printSuccess "Press enter when Rust installation is done") " isDone
      rm rustup-init.exe
      rustup toolchain install stable
      rustup default stable
   else
      printMessage "Skipping Rust installation."
   fi
else
   printSuccess "Rust has been detected on your system, so Rust installation has been skipped"
fi

# Enable the flutter stable channel
printMessage "Setting up Flutter"
flutter channel stable

# Enable linux desktop
flutter config --enable-windows-desktop

# Fix any problems reported by flutter doctor
flutter doctor

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

# Install go-gitlint 
printMessage "Installing go-gitlint."
GOLINT_FILENAME="go-gitlint_1.1.0_windows_x86_64.tar.gz"
if curl --proto '=https' --tlsv1.2 -sSfL https://github.com/llorllale/go-gitlint/releases/download/1.1.0/${GOLINT_FILENAME} -o ${GOLINT_FILENAME}; then
   tar -zxv --directory .githooks/. -f ${GOLINT_FILENAME} gitlint.exe
   rm ${GOLINT_FILENAME}
else
 printError "Failed to install go-gitlint"
fi

# Enable vcpkg integration
# Note: Requires admin
vcpkg integrate install

# Check prerequisites
printMessage "Checking prerequisites."
cargo make flowy_dev
