## How to build on Windows, please follow these simple steps.

## Step 1: Get source code
------------------------------

```shell
git clone https://github.com/AppFlowy-IO/appflowy.git
```

## Step 2: Build app_flowy (Flutter GUI application)
------------------------------

Note:
* Please run the commands in windows cmd rather than powershell
* Following steps are verified on
    - [x] Windows 10 X86_64
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
flutter channel dev
flutter doctor
```
4. Install rust
```shell
# Download rustup.exe from https://win.rustup.rs/x86_64
# Call rustup.exe from powershell or cmd
rustup.exe toolchain install nightly
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
7. Check pre-request
```shell
cargo make flowy_dev
```
8. [Optional] Generate protobuf for dart (optional, if you modify the shared-lib's entities)
```shell
cargo make -p development-windows pb
```
9. [Optional] Build flowy-sdk (dart-ffi)
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

## Step 3: Build Server side application (optional if you don't need to host web service locally)
------------------------------

Note: You can launch postgresql server by using docker container

TBD
