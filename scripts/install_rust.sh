#!/bin/sh

echo 'install rust'
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
echo 'export PATH="$$HOME/.cargo/bin:$$PATH"' >> ~/.bash_profile
source ~/.bash_profile