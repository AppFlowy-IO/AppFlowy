# build the universal binary for AppFlowy on macOS

echo '🚀 ---------------------------------------------------'
echo '🚀 building libdart_ffi.a(x86_64) for AppFlowy on macOS'
cargo make --profile production-mac-x86_64 appflowy-core-release

echo '🚀 ---------------------------------------------------'
echo '🚀 building libdart_ffi.a(arm64) for AppFlowy on macOS'
cargo make --profile production-mac-arm64 appflowy-core-release

echo '🚀 -------------------------------------------------------'
echo '🚀 building libdart_ffi.a(universal) for AppFlowy on macOS'
lipo -create \
    rust-lib/target/x86_64-apple-darwin/release/libdart_ffi.a \
    rust-lib/target/aarch64-apple-darwin/release/libdart_ffi.a \
    -output rust-lib/target/libdart_ffi.a

lipo -archs rust-lib/target/libdart_ffi.a

echo '🚀 ------------------------------------------------------------'
echo '🚀 moving libdart_ffi.a(universal) for AppFlowy Backend Package'
cp -rf rust-lib/target/libdart_ffi.a \
    appflowy_flutter/packages/appflowy_backend/macos/

echo '🚀 ---------------------------------------------------'
echo '🚀 building the flutter application for macOS'
cargo make --env APP_VERSION=$1 --profile production-mac-universal appflowy-macos-universal
