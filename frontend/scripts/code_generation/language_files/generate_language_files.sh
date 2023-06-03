#!/bin/bash

echo "Generating language files"
cd ../../../appflowy_flutter

# Store the current working directory
original_dir=$(pwd)

flutter clean

flutter packages pub get

echo "Specifying source directory for AppFlowy Localizations."
flutter pub run easy_localization:generate -S assets/translations/

echo "Generating language files for AppFlowy."
flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json

echo "Done generating language files."

# Return to the original directory
cd "$original_dir"
