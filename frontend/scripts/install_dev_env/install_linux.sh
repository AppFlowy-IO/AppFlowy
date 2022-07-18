#!/bin/bash

BLUE="\e[34m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"


# Install rust on Linux
read -p 'Do you want to install Rust? [y/N] ' installrust


if [ ${installrust^^} == "Y" ]; then
   echo -e "${BLUE}AppFlowy : Installing Rust.${ENDCOLOR}"
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source $HOME/.cargo/env
   rustup toolchain install stable
   rustup default stable
else
   echo -e "${BLUE}AppFlowy : Skipping Rust installation.${ENDCOLOR}"
fi

# Enable the flutter stable channel
echo -e "${BLUE}AppFlowy : Checking Flutter installation.${ENDCOLOR}"
flutter channel stable

# Enable linux desktop
flutter config --enable-linux-desktop

# Fix any problems reported by flutter doctor
flutter doctor

# Add the githooks directory to your git configuration
echo -e "${BLUE}AppFlowy : Setting up githooks.${ENDCOLOR}"
git config core.hooksPath .githooks

# Change to the frontend directory
cd frontend

# Install cargo make
echo -e "${BLUE}AppFlowy : Installing cargo-make.${ENDCOLOR}"
cargo install --force cargo-make

# Install duckscript
echo -e "${BLUE}AppFlowy : Installing duckscript.${ENDCOLOR}"
cargo install --force duckscript_cli

# Install CommitLint
echo -e "${BLUE}AppFlowy : Installing CommitLint.${ENDCOLOR}"
npm install @commitlint/cli @commitlint/config-conventional --save-dev

