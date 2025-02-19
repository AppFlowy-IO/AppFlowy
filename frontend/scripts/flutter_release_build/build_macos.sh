# This Script is used to build the AppFlowy macOS zip, dmg or pkg
#
# Usage: ./scripts/flutter_release_build/build_macos.sh --build_type <type> --build_arch <arch> --version <version> [--skip-code-generation] [--skip-rebuild-core]
#
# Options:
#   -h, --help    Show this help message and exit
#   --build_type  The type of package to build. Must be one of:
#                 - all: Build all package types
#                 - zip: Build only zip package
#                 - dmg: Build only dmg package
#   --build_arch  The architecture to build. Must be one of:
#                 - x86_64: Build for x86_64 architecture
#                 - arm64: Build for arm64 architecture
#                 - universal: Build for universal architecture
#   --version     The version number (e.g. 0.8.2)
#   --skip-code-generation  Skip the code generation step
#   --skip-rebuild-core  Skip the core rebuild step

show_help() {
    echo "Usage: ./scripts/flutter_release_build/build_macos.sh --build_type <type> --build_arch <arch> --version <version> [--skip-code-generation] [--skip-rebuild-core]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo ""
    echo "Arguments:"
    echo "  --build_type    The type of package to build. Must be one of:"
    echo "                - all: Build all package types"
    echo "                - zip: Build only zip package"
    echo "                  Please install the \033[33mp7zip\033[0m before building the zip package."
    echo "                  For more information, please refer to the https://distributor.leanflutter.dev/makers/zip/."
    echo "                - dmg: Build only dmg package"
    echo "                  Please install the \033[33mappdmg\033[0m before building the dmg package."
    echo "                  For more information, please refer to the https://distributor.leanflutter.dev/makers/dmg/."
    echo "  --build_arch    The architecture to build. Must be one of:"
    echo "                - x86_64: Build for x86_64 architecture"
    echo "                - arm64: Build for arm64 architecture"
    echo "                - universal: Build for universal architecture"
    echo "  --version       The version number (e.g. 0.8.2)"
    echo "  --skip-code-generation   Skip the code generation step. It may save time if you have already generated the code."
    echo "  --skip-rebuild-core      Skip the core rebuild step. It may save time if you have already built the core."
    exit 0
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
fi

# Parse named arguments
while [ $# -gt 0 ]; do
    case "$1" in
    --build_type)
        BUILD_TYPE="$2"
        shift 2
        ;;
    --build_arch)
        BUILD_ARCH="$2"
        shift 2
        ;;
    --version)
        VERSION="$2"
        shift 2
        ;;
    --skip-code-generation)
        SKIP_CODE_GENERATION=true
        shift
        ;;
    --skip-rebuild-core)
        SKIP_REBUILD_CORE=true
        shift
        ;;
    *)
        echo "Unknown parameter: $1"
        show_help
        exit 1
        ;;
    esac
done

# Validate build type argument
if [ -z "$BUILD_TYPE" ]; then
    echo "Please specify build type with --build_type: zip, dmg"
    exit 1
fi

# Validate version argument
if [ -z "$VERSION" ]; then
    echo "Please specify version number with --version (e.g. 0.8.2)"
    exit 1
fi

# Validate build arch argument
if [ -z "$BUILD_ARCH" ]; then
    echo "Please specify build arch with --build_arch: x86_64, arm64 or universal"
    exit 1
fi

if [ "$BUILD_TYPE" != "all" ] && [ "$BUILD_TYPE" != "zip" ] && [ "$BUILD_TYPE" != "dmg" ]; then
    echo "Invalid build type. Must be one of: zip, dmg"
    exit 1
fi

prepare_build() {
    echo "Preparing build..."

    # step 1: build the appflowy-core (rust-lib) based on the build arch
    if [ "$SKIP_REBUILD_CORE" != "true" ]; then
        if [ "$BUILD_ARCH" = "x86_64" ] || [ "$BUILD_ARCH" = "universal" ]; then
            echo "Building appflowy-core for x86_64...(This may take a while)"
            cargo make --profile production-mac-x86_64 appflowy-core-release
        fi

        if [ "$BUILD_ARCH" = "arm64" ] || [ "$BUILD_ARCH" = "universal" ]; then
            echo "Building appflowy-core for arm64...(This may take a while)"
            cargo make --profile production-mac-arm64 appflowy-core-release
        fi

        # step 2 (optional): combine these two libdart_ffi.a into one libdart_ffi.a if the build arch is universal
        if [ "$BUILD_ARCH" = "universal" ]; then
            echo "Combining libdart_ffi.a for universal..."
            lipo -create \
                rust-lib/target/x86_64-apple-darwin/release/libdart_ffi.a \
                rust-lib/target/aarch64-apple-darwin/release/libdart_ffi.a \
                -output rust-lib/target/libdart_ffi.a

            lipo -archs rust-lib/target/libdart_ffi.a

            cp -rf rust-lib/target/libdart_ffi.a \
                appflowy_flutter/packages/appflowy_backend/macos/
        fi
    fi

    # step 3 (optional): generate the flutter code: languages, icons and freezed files.
    if [ "$SKIP_CODE_GENERATION" != "true" ]; then
        echo "Generating the flutter code...(This may take a while)"
        cargo make code_generation
    fi

    # step 4: build the zip package
    echo "Building the zip package..."
    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-macos-zip --skip-clean
    cd ..
}

build_zip() {
    echo "Building zip package version $VERSION..."

    # step 1: check if the macos zip package is built, if not, build the zip package
    if [ ! -f "appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.zip" ]; then
        echo "Macos zip package is not built. Building the zip package..."
        prepare_build

        # step 1.1: move the zip package to the build directory
        mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-macos.zip appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.zip
    fi

    # step 2: unzip the zip package and codesign the app
    unzip appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.zip

    # step 3: codesign the app
    # note: You must install the certificate to the system before codesigning
    codesign --force --options runtime --deep --sign "Developer ID Application: APPFLOWY PTE. LTD" --deep --verbose AppFlowy.app -v

    # step 4: zip the app again
    7z a appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.zip AppFlowy.app

    echo "Zip package built successfully"
}

build_dmg() {
    echo "Building DMG package version $VERSION..."

    # step 1: check if the macos zip package is built, if not, build the zip package
    if [ ! -f "appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.zip" ]; then
        echo "Macos zip package is not built. Building the zip package..."
        build_zip
    fi

    # step 2: unzip the zip package and copy the make_config.json file to the build directory
    unzip appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.zip -d appflowy_flutter/build/$VERSION/
    cp appflowy_flutter/macos/packaging/dmg/make_config.json appflowy_flutter/build/$VERSION/

    # step 3: build the dmg package using appdmg
    # note: You must install the appdmg to the system before building the dmg package
    appdmg appflowy_flutter/build/$VERSION/make_config.json appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.dmg

    # step 4: clear the temp files
    rm -rf appflowy_flutter/build/$VERSION/AppFlowy.app
    rm -rf appflowy_flutter/build/$VERSION/make_config.json

    echo "DMG package built successfully. Please use the following command to submit the dmg package to the notary service:"
    echo "xcrun notarytool submit appflowy_flutter/build/$VERSION/appflowy-$VERSION-macos-$BUILD_ARCH.dmg --apple-id <your-apple-id> --team-id <your-team-id> --password <your-password> -v -f \"json\" --wait"
}

# Build packages based on build type
case $BUILD_TYPE in
"all")
    build_zip
    build_dmg
    ;;
"zip")
    build_zip
    ;;
"dmg")
    build_dmg
    ;;
esac
