#!/bin/sh
#!/usr/bin/env fish

cd rust-lib
cargo clean

CACHE_FILE=lib-infra/.cache
if [ -f "$CACHE_FILE" ]; then
  echo "Remove $CACHE_FILE"
  rm -rf $CACHE_FILE
fi


