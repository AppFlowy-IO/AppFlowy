#!/bin/sh
#!/usr/bin/env fish
echo 'Start building rust sdk'
rustup show

#Env check
#1. rustc --version will be the same as cargo --version
#2. override the toolchain if the current toolchain not equal to the rust-toolchain file specified.
#    rustup override set nightly-2021-04-24
#3. Check your cargo env using the same source by: which cargo
#   1. ~/.bash_profile,
#   2. ~/.bashrc
#   3. ~/.profile
#   4. ~/.zshrc


# TODO: Automatically exec the script base on the current system

# for macOS
cargo make --profile development-mac flowy-sdk-dev

# for Windows
#cargo make --profile development-windows flowy-sdk-dev

# for Linux x86
#cargo make --profile development-linux-x86 flowy-sdk-dev

# for Linux aarch64
#cargo make --profile development-linux-aarch64 flowy-sdk-dev
