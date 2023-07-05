#!/bin/bash

echo "Generating language files"

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

flutter clean

flutter packages pub get

echo "Specifying source directory for AppFlowy Localizations."
dart run easy_localization:generate -S assets/translations/

echo "Generating language files for AppFlowy."
dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json

echo "Done generating language files."

# Return to the original directory
cd "$original_dir"
