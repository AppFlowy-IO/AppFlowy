#!/bin/sh
#!/usr/bin/env fish

cd rust-lib
cargo clean

cd ../../shared-lib
cargo clean

CACHE_FILE=lib-infra/.cache
if [ -d "$CACHE_FILE" ]; then
  echo "Remove $CACHE_FILE"
  rm -rf $CACHE_FILE
fi


