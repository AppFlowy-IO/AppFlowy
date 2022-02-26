#!/bin/sh
#!/usr/bin/env fish

cd rust-lib
cargo clean

cd ../../shared-lib
cargo clean

rm -rf lib-infra/.cache