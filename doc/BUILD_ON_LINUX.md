## How to build on Linux, please follow these simple steps.

**Step 1:**

```shell
git clone https://github.com/AppFlowy-IO/appflowy.git
```

**Step 2:**

Note: Follow steps are verified on Ubuntu 20.04

1. Install pre-requests
```shell
sudo apt-get install build-essential
sudo apt-get install libsqlite3-dev libssl-dev clang cmake ninja-build pkg-config libgtk-3-dev
```
2. Install brew on Linux (TODO: rust installation should not depend on brew)
```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/user/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```
3. Install flutter according to https://docs.flutter.dev/get-started/install/linux
```shell
git clone https://github.com/flutter/flutter.git
cd flutter
echo "export PATH=\$PATH:"`pwd`"/bin" >> ~/.profile
export PATH="$PATH:`pwd`/flutter/bin"
flutter channel dev
flutter config --enable-linux-desktop
```
4. Fix problem reported by flutter doctor
```shell
flutter doctor
# install Android toolchian (optional)
# install Chrome (optional)
```
5. Install rust
```shell
# TODO: replace by rust offical installation step
brew install rustup-init
source $HOME/.cargo/env
rustup toolchain install nightly
rustup default nightly
```
5. Install cargo make
```shell
cd appflowy
cargo install --force cargo-make
```
6. Install duckscript
```shell
cargo install --force duckscript_cli
```
7. Check pre-request
```shell
cargo make flowy_dev
```
8. Generate protobuf for dart (optional)
```shell
cargo make -p development-linux-x86 pb
```
9. Build flowy-sdk-dev (dart-ffi)
```shell
# TODO: for development

# for production
cargo make --profile production-linux-x86 flowy-sdk-release
```
10. Build app_flowy
```shell
# TODO: for development

# for production
cargo make -p production-linux-x86 appflowy-linux
### tips
# run Linux GUI application through x11 on windows (use MobaXterm)
# export DISPLAY=localhost:10
# cd app_flowy/product/0.0.2/linux/Release/AppFlowy
# ./app_flowy
```

**Step 3:**  Server side application

Note: You can launch postgresql server by using docker container

TBD
