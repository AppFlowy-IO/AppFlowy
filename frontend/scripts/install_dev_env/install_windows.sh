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
      $USERPROFILE/.cargo/bin/rustup toolchain install stable
      $USERPROFILE/.cargo/bin/rustup default stable
   else
      printMessage "Skipping Rust installation."
   fi
else
   printSuccess "Rust has been detected on your system, so Rust installation has been skipped"
fi

printMessage "Setting up Flutter"
# Get the current Flutter version
FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K\S+')
# Check if the current version is 3.22.0
if [ "$FLUTTER_VERSION" = "3.22.0" ]; then
   echo "Flutter version is already 3.22.0"
else
   # Get the path to the Flutter SDK
   FLUTTER_PATH=$(which flutter)
   FLUTTER_PATH=${FLUTTER_PATH%/bin/flutter}

   current_dir=$(pwd)

   cd $FLUTTER_PATH
   # Use git to checkout version 3.22.0 of Flutter
   git checkout 3.22.0
   # Get back to current working directory
   cd "$current_dir"

   echo "Switched to Flutter version 3.22.0"
fi

# Add pub cache and cargo to PATH
powershell '[Environment]::SetEnvironmentVariable("PATH", $Env:PATH + ";" + $Env:LOCALAPPDATA + "\Pub\Cache\Bin", [EnvironmentVariableTarget]::User)'
powershell '[Environment]::SetEnvironmentVariable("PATH", $Env:PATH + ";" + $Env:USERPROFILE + "\.cargo\bin", [EnvironmentVariableTarget]::User)'

# Enable linux desktop
flutter config --enable-windows-desktop

# Fix any problems reported by flutter doctor
flutter doctor

# Add the githooks directory to your git configuration
printMessage "Setting up githooks."
git config core.hooksPath .githooks

# Install go-gitlint
printMessage "Installing go-gitlint."
GOLINT_FILENAME="go-gitlint_1.1.0_windows_x86_64.tar.gz"
if curl --proto '=https' --tlsv1.2 -sSfL https://github.com/llorllale/go-gitlint/releases/download/1.1.0/${GOLINT_FILENAME} -o ${GOLINT_FILENAME}; then
   tar -zxv --directory .githooks/. -f ${GOLINT_FILENAME} gitlint.exe
   rm ${GOLINT_FILENAME}
else
   printError "Failed to install go-gitlint"
fi

# Change to the frontend directory
cd frontend

# Install cargo make
printMessage "Installing cargo-make."
$USERPROFILE/.cargo/bin/cargo install --force cargo-make

# Install duckscript
printMessage "Installing duckscript."
$USERPROFILE/.cargo/bin/cargo install --force duckscript_cli

# Enable vcpkg integration
# Note: Requires admin
printMessage "Setting up vcpkg."
vcpkg integrate install

# Check prerequisites
printMessage "Checking prerequisites."
PATH="$PATH;$LOCALAPPDATA\Pub\Cache\bin" bash -c '$USERPROFILE/.cargo/bin/cargo make appflowy-flutter-deps-tools'
