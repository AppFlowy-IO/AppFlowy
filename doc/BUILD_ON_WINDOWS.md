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
1. Install Visual Studio 2019 community. See: https://visualstudio.microsoft.com/downloads/
    - Note: Didn't test Visual Studio 2022. It should also work.
2. Install choco according to https://chocolatey.org/install
3. Install vcpkg according to https://github.com/microsoft/vcpkg#quick-start-windows. Make sure to add vcpkg installation folder to PATH env var.
4. Install flutter according to https://docs.flutter.dev/get-started/install/windows
```shell
flutter channel dev
```
5. Install rust
```shell
choco install rustup.install
rustup toolchain install nightly
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
8. Check pre-request
```shell
cargo make flowy_dev
```
9. Generate protobuf for dart (optional, if you modify the shared-lib's entities)
```shell
cargo make -p development-windows pb
```
10. Build flowy-sdk (dart-ffi)
```shell
# for development
cargo make --profile development-desktop-windows-x86 flowy-sdk-dev
# for production
cargo make --profile production-desktop-windows-x86 flowy-sdk-release
```
11. Build app_flowy
```shell
# for development
cargo make -p development-desktop-windows-x86 appflowy-windows-dev
# for production
cargo make -p production-desktop-windows-x86 appflowy-windows
```

## Step 3: Build Server side application (optional if you don't need to host web service locally)
------------------------------

Note: You can launch postgresql server by using docker container

TBD
