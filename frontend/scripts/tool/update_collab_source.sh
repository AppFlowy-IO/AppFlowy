#!/usr/bin/env bash

# Paths to your Cargo.toml files
REPO_PATH="./AppFlowy-Collab"
CARGO_TOML_1="./rust-lib/Cargo.toml"
REPO_RELATIVE_PATH_1="../AppFlowy-Collab"

CARGO_TOML_2="./appflowy_tauri/src-tauri/Cargo.toml"
REPO_RELATIVE_PATH_2="../../AppFlowy-Collab"

# Function to switch dependencies in a given Cargo.toml
switch_deps() {
    local cargo_toml="$1"
    local repo_path="$2"
    if grep -q 'git = "https://github.com/AppFlowy-IO/AppFlowy-Collab"' "$cargo_toml"; then
        cp "$cargo_toml" "$cargo_toml.bak"
        # Switch to local paths
        for crate in collab collab-folder collab-document collab-database collab-plugins collab-user collab-entity collab-sync-protocol collab-persistence; do
            sed -i '' \
                -e "s#${crate} = { .*git = \"https://github.com/AppFlowy-IO/AppFlowy-Collab\".* }#${crate} = { path = \"$repo_path/$crate\" }#g" \
                "$cargo_toml"
        done
        echo "Switched to local paths in $cargo_toml."
        echo "🙏🏽Switch back to git dependencies by rerunning this script"
    else
        # Switch back to git dependencies
        cp "$cargo_toml.bak" "$cargo_toml"
        echo "Switched back to git dependencies in $cargo_toml."
        rm -rf "$cargo_toml.bak"
    fi
}

# Check if AppFlowy-Collab directory exists
if [ ! -d "$REPO_PATH" ]; then
    echo "AppFlowy-Collab directory not found. Cloning the repository..."
    git clone https://github.com/AppFlowy-IO/AppFlowy-Collab.git "$REPO_PATH"
fi

# Switch dependencies in both Cargo.toml files
switch_deps "$CARGO_TOML_1" "$REPO_RELATIVE_PATH_1"
switch_deps "$CARGO_TOML_2" "$REPO_RELATIVE_PATH_2"
