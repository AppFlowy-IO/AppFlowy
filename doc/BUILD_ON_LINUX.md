# How to build on Linux, please follow these simple steps.

## Step 1: Get source code
------------------------------

```shell
git clone https://github.com/AppFlowy-IO/appflowy.git
```

## Step 2: Build app_flowy (Flutter GUI application)
------------------------------

Note:
* Following steps are verified on
    - [x] lubuntu 20.04 - X86_64
    - [ ] ubuntu 20.04 - aarch64
    - [ ] redhat - X86_64
    - [ ] Arch Linux - X86_64
    - [ ] Deepin - X86_64
    - [ ] Raspberry Pi OS - aarch64
* You may need to disable hardware 3D acceleration if you are running it on a VM. Otherwise, certain GL failures will prevent app from launching

### Detail steps
1. Install prerequisites
```shell
sudo apt-get install curl build-essential libsqlite3-dev libssl-dev clang cmake ninja-build pkg-config libgtk-3-dev unzip
# optional, for generating protobuf in step 8 only
sudo apt-get install protobuf-compiler
```
2. Install rust on Linux
```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup toolchain install nightly
rustup default nightly
```

3. env settings
``` shell
cp backend/configuration/base.example.yaml backend/configuration/base.yaml
cp backend/configuration/.env.example backend/configuration/.env
```
modify  those file

4. Install flutter according to https://docs.flutter.dev/get-started/install/linux
```shell
git clone https://github.com/flutter/flutter.git
cd flutter
echo "export PATH=\$PATH:"`pwd`"/bin" >> ~/.profile
export PATH="$PATH:`pwd`/bin"
flutter channel dev
flutter config --enable-linux-desktop
```
5. Fix problem reported by flutter doctor
```shell
flutter doctor
```
6. Install cargo make
```shell
cd appflowy/frontend
cargo install --force cargo-make
```
7. Install duckscript
```shell
cargo install --force duckscript_cli
```
8. Check prerequisites
```shell
cargo make flowy_dev
```

9. [Optional] Generate protobuf for dart (optional, if you modify the shared-lib's entities)
```shell
# Make sure to install protobuf-compiler at first. See step 1
cargo make -p development-linux-x86 pb
```
10. [Optional] Build flowy-sdk-dev (dart-ffi), step 10 covers this step

```shell
# for development
cargo make --profile development-linux-x86 flowy-sdk-dev

# for production
cargo make --profile production-linux-x86 flowy-sdk-release
```

11. Build app_flowy
```shell
# for development
cargo make -p development-linux-x86 appflowy-linux-dev

# for production, find binary from app_flowy/product/<version>/linux/<build type>/AppFlowy/
cargo make -p production-linux-x86 appflowy-linux

# tips
# run Linux GUI application through x11 on windows (use MobaXterm)
# for instance:
# export DISPLAY=localhost:10
# cd app_flowy/product/0.0.2/linux/Release/AppFlowy
# ./app_flowy
```

## [Optional] Step 3: Build Server side application (optional if you don't need to host web service locally)
------------------------------

Note: You can launch postgresql server by using docker container

TBD
