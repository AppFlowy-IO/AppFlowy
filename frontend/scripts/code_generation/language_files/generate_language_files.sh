#!/bin/bash

echo "Generating language files"

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

# copy the resources/translations folder to
# the appflowy_flutter/assets/translation directory
rm -rf assets/translations/
mkdir -p assets/translations/
cp -f ../resources/translations/*.json assets/translations/

# the ci alwayas return a 'null check operator used on a null value' error.
# so we force to exec the below command to avoid the error.
# https://github.com/dart-lang/pub/issues/3314
flutter pub get
flutter packages pub get

echo "Specifying source directory for AppFlowy Localizations."
dart run easy_localization:generate -S assets/translations/

echo "Generating language files for AppFlowy."
dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json

echo "Done generating language files."

# Return to the original directory
cd "$original_dir"
