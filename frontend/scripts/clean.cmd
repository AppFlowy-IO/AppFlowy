cd rust-lib
cargo clean

cd ../../shared-lib

if exist "lib-infra/.cache" (
    rmdir /s/q "lib-infra/.cache"
)