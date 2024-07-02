#!/usr/bin/env bash

# Ensure a new revision ID is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <new_revision_id>"
    exit 1
fi

NEW_REV="$1"
echo "New revision: $NEW_REV"
directories=("rust-lib" "appflowy_tauri/src-tauri" "appflowy_web_app/src-tauri")

for dir in "${directories[@]}"; do
    echo "Updating $dir"
    pushd "$dir" > /dev/null

    sed -i.bak "/^client-api[[:alnum:]-]*[[:space:]]*=/s/rev = \"[a-fA-F0-9]\{6,40\}\"/rev = \"$NEW_REV\"/g" Cargo.toml

    # Detect changed crates
    client_api_crates=($(grep -E '^client-api[a-zA-Z0-9_-]* =' Cargo.toml | awk -F'=' '{print $1}' | tr -d ' '))

    # Update only the changed crates in Cargo.lock
    for crate in "${client_api_crates[@]}"; do
        echo "Updating $crate"
        cargo update -p $crate
    done

    popd > /dev/null
done
