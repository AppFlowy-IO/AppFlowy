#!/bin/bash

echo "Generating language files"

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

flutter packages pub get

echo "Generating svgs for AppFlowy."
dart run flowy_svg

echo "Done generating svg files."

# Return to the original directory
cd "$original_dir"
