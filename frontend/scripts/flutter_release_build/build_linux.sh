# This Script is used to build the AppFlowy Linux zip, deb, rpm and AppImage.
#
# Usage: sudo ./build_linux.sh [-h] <build_type> <version>
#
# Options:
#   -h            Show this help message and exit
#
# Usage: sudo ./scripts/flutter_release_build/build_linux.sh <build_type> <version>
#
# Arguments:
#   build_type    The type of package to build. Must be one of:
#                 - all: Build all package types
#                 - zip: Build only zip package
#                 - deb: Build only deb package
#                 - rpm: Build only rpm package
#                 - appimage: Build only AppImage package
#   version       The version number (e.g. 0.8.2)

show_help() {
    echo "Usage: sudo ./scripts/flutter_release_build/build_linux.sh [-h] <build_type> <version>"
    echo ""
    echo "Options:"
    echo "  -h            Show this help message and exit"
    echo ""
    echo "Arguments:"
    echo "  build_type    The type of package to build. Must be one of:"
    echo "                - all: Build all package types"
    echo "                - zip: Build only zip package"
    echo "                - deb: Build only deb package"
    echo "                - rpm: Build only rpm package."
    echo "                  Please install the \033[33mrpm\033[0m and \033[33mpatchelf\033[0m before building the rpm package."
    echo "                  For more information, please refer to the https://distributor.leanflutter.dev/makers/rpm/."
    echo "                - appimage: Build only AppImage package."
    echo "                  Please install the \033[33mlocate\033[0m and \033[33mappimagetool\033[0m before building the AppImage package."
    echo "                  For more information, please refer to the https://distributor.leanflutter.dev/makers/appimage/."
    echo "  version       The version number (e.g. 0.8.2)"
    exit 0
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
fi

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script with sudo"
    exit 1
fi

# Get the build type and version from command line arguments
BUILD_TYPE=$1
VERSION=$2

# Validate build type argument
if [ -z "$BUILD_TYPE" ]; then
    echo "Please specify build type: all, zip, deb, rpm or appimage"
    exit 1
fi

# Validate version argument
if [ -z "$VERSION" ]; then
    echo "Please specify version number (e.g. 0.8.2)"
    exit 1
fi

if [ "$BUILD_TYPE" != "all" ] && [ "$BUILD_TYPE" != "zip" ] && [ "$BUILD_TYPE" != "deb" ] && [ "$BUILD_TYPE" != "rpm" ] && [ "$BUILD_TYPE" != "appimage" ]; then
    echo "Invalid build type. Must be one of: all, zip, deb, rpm or appimage"
    exit 1
fi

prepare_build() {
    echo "Preparing build..."

    # Build the rust-lib with version
    cargo make --env APP_VERSION=$VERSION --profile production-linux-x86_64 appflowy-core-release
    cargo make --env APP_VERSION=$VERSION --profile production-linux-x86_64 code_generation
}

build_zip() {
    echo "Building zip package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-zip --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.zip appflowy_flutter/build/$VERSION/appflowy-$VERSION-linux-x86_64.zip

    echo "Zip package built successfully"
}

build_deb() {
    echo "Building deb package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-deb --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.deb appflowy_flutter/build/$VERSION/appflowy-$VERSION-linux-x86_64.deb

    echo "Deb package built successfully"
}

build_rpm() {
    echo "Building rpm package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-rpm --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.rpm appflowy_flutter/build/$VERSION/appflowy-$VERSION-linux-x86_64.rpm

    echo "RPM package built successfully"
}

# Function to build AppImage package
build_appimage() {
    echo "Building AppImage package version $VERSION..."

    prepare_build

    cd appflowy_flutter
    flutter_distributor release --name=prod --jobs=release-prod-linux-appimage --skip-clean
    cd ..
    mv appflowy_flutter/build/$VERSION/appflowy-$VERSION+$VERSION-linux.AppImage appflowy_flutter/build/$VERSION/appflowy-$VERSION-linux-x86_64.AppImage

    echo "AppImage package built successfully"
}

# Build packages based on build type
case $BUILD_TYPE in
"all")
    build_zip
    build_deb
    build_rpm
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
esac
