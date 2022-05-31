#!/bin/sh
#!/usr/bin/env fish
echo 'Start building rust sdk'

rustup show

#Env check
#1. rustc --version will be the same as cargo --version
#2. override the toolchain if the current toolchain not equal to the rust-toolchain file specified.
#    rustup override set stable-2021-04-24
#3. Check your cargo env using the same source by: which cargo
#   1. ~/.bash_profile,
#   2. ~/.bashrc
#   3. ~/.profile
#   4. ~/.zshrc


case "$FLOWY_DEV_ENV" in
Linux-aarch64) 
 cargo make --profile development-linux-aarch64 flowy-sdk-dev
 ;;

Linux-x86)
 cargo make --profile development-linux-x86 flowy-sdk-dev
 ;;

macOS)
 cargo make --profile "development-mac-$(uname -m)" flowy-sdk-dev
 ;;

Windows) 
 cargo make --profile development-windows flowy-sdk-dev
 ;;

*)
 # All undefined cases
 echo "[ERROR] The FLOWY_DEV_ENV environment variable must be set. Please see the GitHub wiki for instructions."
 exit 1
 ;;
esac
