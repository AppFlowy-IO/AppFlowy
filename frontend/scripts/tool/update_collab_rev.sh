#!/bin/bash

# Ensure a new revision ID is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <new_revision_id>"
    exit 1
fi

NEW_REV="$1"
echo "New revision: $NEW_REV"
directories=("rust-lib" "appflowy_tauri/src-tauri")

for dir in "${directories[@]}"; do
    echo "Updating $dir"

    cd "$dir"
    sed -i.bak "/^collab[[:alnum:]-]*[[:space:]]*=/s/rev = \"[a-fA-F0-9]\{6,40\}\"/rev = \"$NEW_REV\"/g" Cargo.toml

    # Detect changed crates
    collab_crates=($(grep -E '^collab[a-zA-Z0-9_-]* =' Cargo.toml | awk -F'=' '{print $1}' | tr -d ' '))

    # Update only the changed crates in Cargo.lock
    for crate in "${collab_crates[@]}"; do
        echo "Updating $crate"
        cargo update -p $crate
    done

    cd ..
done

