#!/bin/bash
set -u
set -e

# Check if rust targets are installed
rustup target add \
aarch64-linux-android \
armv7-linux-androideabi \
i686-linux-android \
x86_64-linux-android

export DIR=$(realpath ${DIR:-$(pwd)})

# The linker and clang are defined in ~/.cargo/config

# You  need to set the NDK path in .profile or set it anywhere then call it here
source ~/.profile

DEST="../app_flowy/android/app/src/main/jniLibs"

#Remove previous folders
rm -rf $DEST/arm64-v8a
rm -rf $DEST/armeabi-v7a
rm -rf $DEST/x86
rm -rf $DEST/x86_64

cargo ndk --target armeabi-v7a -o $DEST build --release

cargo ndk --target arm64-v8a -o $DEST build --release

cargo ndk --target x86 -o $DEST build --release

cargo ndk --target x86_64 -o $DEST build --release
