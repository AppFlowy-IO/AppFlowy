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

    sed -i.bak "/^collab[[:alnum:]-]*[[:space:]]*=/s/rev = \"[a-fA-F0-9]\{6,40\}\"/rev = \"$NEW_REV\"/g" Cargo.toml

    # Detect changed crates
    collab_crates=($(grep -E '^collab[a-zA-Z0-9_-]* =' Cargo.toml | awk -F'=' '{print $1}' | tr -d ' '))

    # Update only the changed crates in Cargo.lock

    crates_to_update=""
    for crate in "${collab_crates[@]}"; do
        crates_to_update="$crates_to_update -p $crate"
    done

    # Update all the specified crates at once
    echo "Updating crates: $crates_to_update"
    cargo update $crates_to_update

    popd > /dev/null
done

