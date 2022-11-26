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
Linux) 
 cargo make --profile "development-linux-$(uname -m)" appflowy-sdk-dev
 ;;

macOS)
 cargo make --profile "development-mac-$(uname -m)" appflowy-sdk-dev
 ;;

Windows) 
 cargo make --profile development-windows appflowy-sdk-dev
 ;;

*)
 # All undefined cases
 echo "[ERROR] The FLOWY_DEV_ENV environment variable must be set. Please see the GitHub wiki for instructions."
 exit 1
 ;;
esac
