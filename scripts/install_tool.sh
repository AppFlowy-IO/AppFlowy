#!/bin/sh

#targets
rustup target add x86_64-apple-darwin

#tools
echo 'install tools'
rustup component add rustfmt
cargo install cargo-expand
cargo install cargo-watch
cargo install cargo-cache

#protobuf code gen env
brew install protobuf@3.13
cargo install --version 2.20.0 protobuf-codegen