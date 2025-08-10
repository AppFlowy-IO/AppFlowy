# Building AppFlowy from Source

This guide provides comprehensive instructions for building AppFlowy from source code on all supported platforms.

## Prerequisites

Before building AppFlowy, ensure you have the following installed:

### All Platforms
- [Git](https://git-scm.com/)
- [Rust](https://rustup.rs/) (1.70 or later)
- [Flutter](https://flutter.dev/docs/get-started/install) (3.13.19 or later)
- [cargo-make](https://github.com/sagiegurari/cargo-make) - Install with: `cargo install cargo-make`

### Platform-Specific Requirements

#### Windows
- [Visual Studio 2019/2022](https://visualstudio.microsoft.com/) with C++ development tools
- [vcpkg](https://github.com/microsoft/vcpkg)

#### macOS
- Xcode Command Line Tools: `xcode-select --install`

#### Linux
- Build essentials: `sudo apt install build-essential pkg-config libssl-dev`
- Additional dependencies: `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev`

## Building for Desktop

### 1. Clone the Repository
```bash
git clone https://github.com/AppFlowy-IO/AppFlowy.git
cd AppFlowy
```

### 2. Build for Your Platform

#### Windows
```bash
cd frontend
cargo make appflowy-windows
```

#### macOS
```bash
cd frontend
cargo make appflowy-macos
```

#### Linux
```bash
cd frontend
cargo make appflowy-linux
```

### 3. Run the Application

After building, the executable will be located in:
- **Windows**: `frontend/appflowy_flutter/product/[version]/windows/Release/AppFlowy/`
- **macOS**: `frontend/appflowy_flutter/product/[version]/macos/Release/AppFlowy.app/`
- **Linux**: `frontend/appflowy_flutter/product/[version]/linux/Release/AppFlowy/`

## Building for Mobile

### iOS

#### Prerequisites
- macOS with Xcode installed
- iOS development setup for Flutter

#### Build Steps
```bash
cd frontend
cargo make appflowy-ios
```

The iOS app will be built and available in `frontend/appflowy_flutter/build/ios/`.

### Android

#### Prerequisites

**All Platforms:**
- [Android NDK](https://developer.android.com/ndk/downloads/) version 24
- cargo-ndk: `cargo install cargo-ndk`

#### Detailed Setup Instructions

For comprehensive Android build setup including Windows support, please refer to the [Android-specific build guide](../frontend/appflowy_flutter/android/README.md) which covers:

- Platform-specific environment variable setup
- Cargo configuration for all operating systems
- NDK 24 clang fixes
- Path configuration
- Troubleshooting common issues

#### Build Steps
```bash
cd frontend
cargo make appflowy-android
```

The Android APK will be built and available in `frontend/appflowy_flutter/build/app/outputs/flutter-apk/`.

## Development Builds

For faster development builds without optimizations:

### Desktop Development
```bash
cd frontend
cargo make appflowy-dev  # Uses platform-specific aliases
```

### Mobile Development
```bash
# iOS development build
cd frontend
cargo make appflowy-ios-dev

# Android development build
cd frontend
cargo make appflowy-android-dev
```

## Troubleshooting

### Common Issues

1. **Flutter Doctor Issues**: Run `flutter doctor` to check for missing dependencies
2. **Rust Version**: Ensure you're using Rust 1.70 or later
3. **Path Issues**: Make sure all tools are in your system PATH
4. **NDK Issues**: Verify ANDROID_NDK_HOME is set correctly

### Platform-Specific Issues

#### Windows
- Ensure Visual Studio C++ tools are installed
- Check that vcpkg is properly configured
- Use PowerShell or Command Prompt, not Git Bash for building

#### macOS
- Ensure Xcode Command Line Tools are installed
- For iOS builds, you need a full Xcode installation

#### Linux
- Install all required system dependencies
- Check that pkg-config can find required libraries

### Getting Help

- Check the [AppFlowy Documentation](https://docs.appflowy.io/)
- Join our [Discord](https://discord.gg/9Q2xaN37tV) for community support
- Report issues on [GitHub](https://github.com/AppFlowy-IO/AppFlowy/issues)

## Additional Resources

- [AppFlowy Development Guide](https://docs.appflowy.io/docs/documentation/appflowy/from-source)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Android-specific instructions](../frontend/appflowy_flutter/android/README.md)
