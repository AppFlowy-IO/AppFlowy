# This Script is used to build the AppFlowy linux zip, deb, rpm or appimage
#
# Usage: ./scripts/flutter_release_build/build_linux.sh --build_type <type> --build_arch <arch> --version <version> [--skip-code-generation] [--skip-rebuild-core]
#
# Options:
#   -h, --help    Show this help message and exit
#   --build_type  The type of package to build. Must be one of:
#                 - all: Build all package types
#                 - zip: Build only zip package
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

# Validate build type argument
if [ -z "$BUILD_TYPE" ]; then
    echo "Please specify build type with --build_type: zip, deb, rpm, appimage"
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

if [ "$BUILD_TYPE" != "all" ] && [ "$BUILD_TYPE" != "zip" ] && [ "$BUILD_TYPE" != "deb" ] && [ "$BUILD_TYPE" != "rpm" ] && [ "$BUILD_TYPE" != "appimage" ]; then
    echo "Invalid build type. Must be one of: zip, deb, rpm, appimage"
    exit 1
fi

has_built_core=false
has_generated_code=false

prepare_build() {
    echo "Preparing build..."

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
