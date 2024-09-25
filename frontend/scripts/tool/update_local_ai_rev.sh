#!/bin/bash

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

    # Define the crates to update
    crates=("appflowy-local-ai" "appflowy-plugin")

    for crate in "${crates[@]}"; do
        sed -i.bak "/^${crate}[[:alnum:]-]*[[:space:]]*=/s/rev = \"[a-fA-F0-9]\{6,40\}\"/rev = \"$NEW_REV\"/g" Cargo.toml
    done

    # Construct the crates_to_update variable
    crates_to_update=""
    for crate in "${crates[@]}"; do
        crates_to_update="$crates_to_update -p $crate"
    done

    # Update all the specified crates at once
    if [ -n "$crates_to_update" ]; then
        echo "Updating crates: $crates_to_update"
        cargo update $crates_to_update 2> /dev/null
    fi

    popd > /dev/null
done
