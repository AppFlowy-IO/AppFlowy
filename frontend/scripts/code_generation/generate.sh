#!/usr/bin/env bash

# Store the current working directory
original_dir=$(pwd)

# Change the current working directory to the script's location
cd "$(dirname "$0")"

# Call the script in the 'language_files' folder
echo "Generating files using easy_localization"
cd language_files
# Allow execution permissions on CI
chmod +x ./generate_language_files.sh
./generate_language_files.sh "$@"

# Return to the main script directory
cd ..

# Call the script in the 'freezed' folder
echo "Generating files using build_runner"
cd freezed
# Allow execution permissions on CI
chmod +x ./generate_freezed.sh
./generate_freezed.sh "$@"

# Return to the main script directory
cd ..

echo "Generating svg files using flowy_svg"
cd flowy_icons
# Allow execution permissions on CI
chmod +x ./generate_flowy_icons.sh
./generate_flowy_icons.sh "$@"

# Return to the original directory
cd "$original_dir"
