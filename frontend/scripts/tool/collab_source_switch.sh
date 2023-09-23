#!/bin/bash

# Paths to your Cargo.toml files
CARGO_TOML_1="./Cargo.toml"
CARGO_TOML_2="./appflowy_tauri/src-tauri/Cargo.toml"
REPO_PATH="../AppFlowy-Collab"

# Function to switch dependencies in a given Cargo.toml
switch_deps() {
    local cargo_toml="$1"
    if grep -q 'git = "https://github.com/AppFlowy-IO/AppFlowy-Collab"' "$cargo_toml"; then
        # Switch to local paths
        sed -i.bak \
            -e 's#collab = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab = { path = "../AppFlowy-Collab/collab" }#g' \
            -e 's#collab-folder = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-folder = { path = "../AppFlowy-Collab/collab-folder" }#g' \
            -e 's#collab-document = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-document = { path = "../AppFlowy-Collab/collab-document" }#g' \
            -e 's#collab-database = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-database = { path = "../AppFlowy-Collab/collab-database" }#g' \
            -e 's#collab-plugins = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-plugins = { path = "../AppFlowy-Collab/collab-plugins" }#g' \
            -e 's#collab-user = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-user = { path = "../AppFlowy-Collab/collab-user" }#g' \
            -e 's#collab-define = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-define = { path = "../AppFlowy-Collab/collab-define" }#g' \
            -e 's#collab-sync-protocol = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-sync-protocol = { path = "../AppFlowy-Collab/collab-sync-protocol" }#g' \
            -e 's#collab-persistence = { git = "https://github.com/AppFlowy-IO/AppFlowy-Collab", rev = "[a-f0-9]*" }#collab-persistence = { path = "../AppFlowy-Collab/collab-persistence" }#g' \
            "$cargo_toml"
        echo "Switched to local paths in $cargo_toml."
    else
        # Switch back to git dependencies
        cp "$cargo_toml.bak" "$cargo_toml"
        echo "Switched back to git dependencies in $cargo_toml."
    fi
}

# Check if AppFlowy-Collab directory exists
if [ ! -d "$REPO_PATH" ]; then
    echo "AppFlowy-Collab directory not found. Cloning the repository..."
    git clone https://github.com/AppFlowy-IO/AppFlowy-Collab.git "$REPO_PATH"
else
    echo "AppFlowy-Collab directory found. Pulling the latest code..."
    # Save the current directory
    CURRENT_DIR=$(pwd)
    # Navigate to the AppFlowy-Collab directory
    cd "$REPO_PATH"
    # Pull the latest code
    git pull
    # Navigate back to the original directory
    cd "$CURRENT_DIR"
fi

# Switch dependencies in both Cargo.toml files
switch_deps "$CARGO_TOML_1"
switch_deps "$CARGO_TOML_2"
