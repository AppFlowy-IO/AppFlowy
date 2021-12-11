# How to build on Linux, please follow these simple steps.

Note:
* The following steps are verified on
    - [x] lubuntu 20.04 - X86_64
    - [ ] ubuntu 20.04 - aarch64
    - [ ] redhat - X86_64
    - [x] Arch Linux - X86_64
    - [ ] Deepin - X86_64
    - [ ] Raspberry Pi OS - aarch64
* You may need to disable hardware 3D acceleration if you are running AppFlowy in a VM. Otherwise, certain GL failures will prevent the app from launching.


## Step 1: Install your build environment
------------------------------
There's no point continuing if this doesn't work for you. Feel free to ask questions on our Discord so that we may refire this document and make the process as easy as possible for you.

1. Install system prerequisites
```shell
#Ubuntu
sudo apt-get install curl build-essential libsqlite3-dev libssl-dev clang cmake ninja-build pkg-config libgtk-3-dev unzip
# optional, for generating protobuf in step 8 only
sudo apt-get install protobuf-compiler
```
```shell
#Arch
yay -S curl base-devel sqlite openssl clang cmake ninja pkg-config gtk3 unzip
# optional, for generating protobuf in step 8 only
#(Caution: protobuf does not work on Arch at the moment.)
#yay -S protobuf-compiler
```

1. Install rust on Linux
```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup toolchain install nightly
rustup default nightly
```

1. Install flutter according to https://docs.flutter.dev/get-started/install/linux
```shell
git clone https://github.com/flutter/flutter.git
cd flutter
echo "export PATH=\$PATH:"`pwd`"/bin" >> ~/.profile
export PATH="$PATH:`pwd`/bin"
flutter channel stable
```
1. Enable linux desktop
```
flutter config --enable-linux-desktop
```
1. Fix any problems reported by flutter doctor
```shell
flutter doctor
```

## Step 2: Get the source code
------------------------------

```shell
git clone https://github.com/AppFlowy-IO/appflowy.git
```

However, you should fork the code instead if you wish to submit patches.

## Step 3: Build app_flowy (Flutter GUI application)
------------------------------

1. Change to the frontend directory
```shell
cd [appflowy/]frontend
```
1. Install cargo make
```shell
cargo install --force cargo-make
```
1. Install duckscript
```shell
cargo install --force duckscript_cli
```
1. Check prerequisites
```shell
cargo make flowy_dev
```
1. [Optional] Generate protobuf for dart (if you wish to modify the shared-lib's entities)
```shell
# Caution : Not working on Arch Linux yet
# Make sure to install protobuf-compiler at first. See step 1
cargo make -p development-linux-x86 pb
```
1. [Optional] Build flowy-sdk-dev (dart-ffi)
```shell
# for development
cargo make --profile development-linux-x86 flowy-sdk-dev

# for production
cargo make --profile production-linux-x86 flowy-sdk-release
```

1. Build app_flowy
```shell
# for development
cargo make -p development-linux-x86 appflowy-linux-dev

# for production, find binary from app_flowy/product/<version>/linux/<build type>/AppFlowy/
cargo make -p production-linux-x86 appflowy-linux
```

## Step 4: Run the application
------------------------------
```
cd [frontend/]app_flowy/product/0.0.2/linux/Debug/AppFlowy/app_flowy
./app_flowy
```
# run Linux GUI application through x11 on windows (use MobaXterm)
# for instance:
# export DISPLAY=localhost:10

## [Optional] Step 5: Build Server side application (if you need to host web service locally)
------------------------------

Note: You can launch postgresql server by using docker container

TBD
