## How to build on Windows, please follow these simple steps.

## Step 1: Get source code
------------------------------

```shell
git clone https://github.com/AppFlowy-IO/appflowy.git
```

## Step 2: Build app_flowy (Flutter GUI application)
------------------------------

Note:
* Both Windows cmd and powershell can be used for running commands
* Following steps are verified on
    - [ ] Windows 10 X86_64
    - [ ] Windows 10 arm64
    - [ ] Windows 11 X86_64
    - [ ] Windows 11 arm64

### Detail steps
1. Install Visual Studio 2022 build tools. Download from https://visualstudio.microsoft.com/downloads/
    - In section of "All Downloads" => "Tools for Visual Studio 2022" => Build Tools for Visual Studio 2022, hit Download button to get it.
    - Launch "vs_BuildTools.exe" to install
2. Install vcpkg according to https://github.com/microsoft/vcpkg#quick-start-windows. Make sure to add vcpkg installation folder to PATH env var.
3. Install flutter according to https://docs.flutter.dev/get-started/install/windows
```shell
flutter channel stable
flutter doctor
```
4. Install rust
```shell
# Download rustup.exe from https://win.rustup.rs/x86_64
# Call rustup.exe from powershell or cmd
.\rustup-init.exe --default-toolchain nightly --default-host x86_64-pc-windows-msvc -y
# Note: you probably need to re-open termial to get cargo command be available in PATH var
```
5. Install cargo make
```shell
cd appflowy/frontend
cargo install --force cargo-make
```
6. Install duckscript
```shell
cargo install --force duckscript_cli
```
7. Check prerequisites
```shell
cargo make flowy_dev
```
8. [Optional] Generate protobuf for dart (optional, if you modify the shared-lib's entities)
```shell
# Need to download protoc tools and add it's bin folder into PATH env var.
# Download protoc from https://github.com/protocolbuffers/protobuf/releases. The latest one is protoc-3.19.1-win64.zip
cargo make -p development-windows pb
```
9. [Optional] Build flowy-sdk (dart-ffi), step 10 covers this step
```shell
# for development
cargo make --profile development-windows-x86 flowy-sdk-dev
# for production
cargo make --profile production-windows-x86 flowy-sdk-release
```
10. Build app_flowy
```shell
# for development
cargo make -p development-windows-x86 appflowy-windows-dev
# for production
cargo make -p production-windows-x86 appflowy-windows
```

## [Optional] Step 3: Build Server side application (optional if you don't need to host web service locally)
------------------------------

Note: You can launch postgresql server by using docker container

TBD
