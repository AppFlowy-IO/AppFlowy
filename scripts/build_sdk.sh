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
cargo make desktop
#cargo make gen_dart_event