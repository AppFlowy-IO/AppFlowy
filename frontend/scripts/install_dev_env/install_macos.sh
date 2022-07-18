#!/bin/bash

BLUE="\e[34m"
RED="\e[31m"
ENDCOLOR="\e[0m"

# Install rust on Linux
echo -e "${BLUE}AppFlowy : The Rust programming language is required to compile AppFlowy.${ENDCOLOR}"
echo -e "${BLUE}AppFlowy : We can install it now if you don't already have it on your system.${ENDCOLOR}"

read -p "${BLUE}AppFlowy : Do you want to install Rust? [y/N]${ENDCOLOR} " installrust

if [ ${installrust^^} == "Y" ]; then
   echo -e "${BLUE}AppFlowy : Installing Rust.${ENDCOLOR}"
   brew 'rustup-init'
   rustup-init -y --default-toolchain=stable
else
   echo -e "${BLUE}AppFlowy : Skipping Rust installation.${ENDCOLOR}"
fi

# Install sqllite
echo -e "${BLUE}AppFlowy : Installing SqlLite3.${ENDCOLOR}"
brew 'sqlite3' 

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

# Check prerequisites
echo -e "${BLUE}AppFlowy : Checking prerequisites.${ENDCOLOR}"
cargo make flowy_dev
