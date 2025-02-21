#!/bin/bash
# This Script is used to build the AppFlowy linux zip, deb, rpm or appimage
#
# Usage: ./scripts/flutter_release_build/build_linux.sh --build_type <type> --build_arch <arch> --version <version> [--skip-code-generation] [--skip-rebuild-core]
#
# Options:
#   -h, --help    Show this help message and exit
#   --build_type  The type of package to build. Must be one of:
#                 - all: Build all package types
#                 - zip: Build only zip package
#                 - tar.xz: Build only tar.xz package
#                 - deb: Build only deb package
#                 - rpm: Build only rpm package
#                 - appimage: Build only appimage package
#   --build_arch  The architecture to build. Must be one of:
#                 - x86_64: Build for x86_64 architecture
#                 - arm64: Build for arm64 architecture (not supported yet)
#   --version     The version number (e.g. 0.8.2)
#   --skip-code-generation  Skip the code generation step
#   --skip-rebuild-core  Skip the core rebuild step

show_help() {
    echo "Usage: ./scripts/flutter_release_build/build_linux.sh --build_type <type> --build_arch <arch> --version <version> [--skip-code-generation] [--skip-rebuild-core]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo ""
    echo "Arguments:"
    echo "  --build_type    The type of package to build. Must be one of:"
    echo "                - all: Build all package types"
    echo "                - zip: Build only zip package"
    echo "                - tar.xz: Build only tar.xz package"
    echo "                - deb: Build only deb package"
    echo "                - rpm: Build only rpm package"
    echo "                  Please install the \033[33mrpm-build\033[0m and \033[33mpatchelf\033[0m before building the rpm and appimage package."
    echo "                  For more information, please refer to the https://distributor.leanflutter.dev/makers/rpm/."
    echo "                - appimage: Build only appimage package"
    echo "                  Please install the \033[33mlocate\033[0m and \033[33mappimagetool\033[0m before building the appimage package."
    echo "                  For more information, please refer to the https://distributor.leanflutter.dev/makers/appimage/."
    echo "  --build_arch    The architecture to build. Must be one of:"
    echo "                - x86_64: Build for x86_64 architecture"
    echo "                - arm64: Build for arm64 architecture (not supported yet)"
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

clear_cache() {
    echo "Clearing the cache..."
    rm -rf appflowy_flutter/build/$VERSION/
}

info() {
    echo "🚀 \033[32m$1\033[0m"
}

error() {
    echo "🚨 \033[31m$1\033[0m"
}

# Validate build type argument
if [ -z "$BUILD_TYPE" ]; then
    error "Please specify build type with --build_type: all, zip, tar.xz, deb, rpm, appimage"
    exit 1
fi

# Validate version argument
if [ -z "$VERSION" ]; then
    error "Please specify version number with --version (e.g. 0.8.2)"
    exit 1
fi

# Validate build arch argument
if [ -z "$BUILD_ARCH" ]; then
    error "Please specify build arch with --build_arch: x86_64, arm64 or universal"
    exit 1
fi

if [ "$BUILD_TYPE" != "all" ] && [ "$BUILD_TYPE" != "zip" ] && [ "$BUILD_TYPE" != "tar.xz" ] && [ "$BUILD_TYPE" != "deb" ] && [ "$BUILD_TYPE" != "rpm" ] && [ "$BUILD_TYPE" != "appimage" ]; then
    error "Invalid build type. Must be one of: all, zip, tar.xz, deb, rpm, appimage"
    exit 1
fi

has_built_core=false
has_generated_code=false

prepare_build() {
    info "Preparing build..."

    # Build the rust-lib with version
    if [ "$SKIP_REBUILD_CORE" != "true" ] && [ "$has_built_core" != "true" ]; then
        cargo make --env APP_VERSION=$VERSION --profile production-linux-$BUILD_ARCH appflowy-core-release
        has_built_core=true
    fi

    if [ "$SKIP_CODE_GENERATION" != "true" ] && [ "$has_generated_code" != "true" ]; then
        cargo make --env APP_VERSION=$VERSION --profile production-linux-$BUILD_ARCH code_generation
        has_generated_code=true
    fi
}

build_zip() {
    info "Building zip package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-zip --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.zip appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.zip

    info "Zip package built successfully. The zip package is located at appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.zip"
}

build_deb() {
    info "Building deb package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-deb --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.deb appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.deb

    info "Deb package built successfully. The deb package is located at appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.deb"
}

build_rpm() {
    info "Building rpm package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-rpm --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.rpm appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.rpm

    info "RPM package built successfully. The RPM package is located at appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.rpm"
}

# Function to build AppImage package
build_appimage() {
    info "Building AppImage package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-appimage --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.AppImage appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.AppImage

    info "AppImage package built successfully. The AppImage package is located at appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.AppImage"
}

build_tar_xz() {
    info "Building tar.xz package version $VERSION..."

    prepare_build

    # step 1: check if the linux zip package is built, if not, build the zip package
    if [ ! -f "appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.zip" ]; then
        info "Linux zip package is not built. Building the zip package..."
        build_zip
    fi

    # step 2: unzip the zip package
    unzip appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.zip -d appflowy_flutter/build/$VERSION/

    # check if the AppFlowy directory exists
    if [ ! -d "appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64" ]; then
        error "AppFlowy directory doesn't exist. Please check the zip package."
        exit 1
    fi

    # step 3: build the tar.xz package
    tar -cJvf appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.tar.xz -C appflowy_flutter/build/$VERSION/ AppFlowy-$VERSION-linux-x86_64

    # step 4: clean up the extracted directory
    rm -rf appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64

    info "Tar.xz package built successfully. The tar.xz package is located at appflowy_flutter/build/$VERSION/AppFlowy-$VERSION-linux-x86_64.tar.xz"
}

clear_cache

# Build packages based on build type
case $BUILD_TYPE in
"all")
    build_zip
    build_deb
    build_rpm
    build_tar_xz
    build_appimage
    ;;
"zip")
    build_zip
    ;;
"deb")
    build_deb
    ;;
"rpm")
    build_rpm
    ;;
"appimage")
    build_appimage
    ;;
"tar.xz")
    build_tar_xz
    ;;
esac
