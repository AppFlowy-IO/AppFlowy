#!/bin/bash

echo "Generating flowy icon files"

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

rm -rf assets/flowy_icons/
mkdir -p assets/flowy_icons/
rsync -r ../resources/flowy_icons/ assets/flowy_icons/

flutter pub get
flutter packages pub get

echo "Generating FlowySvg classes"
dart run flowy_svg

echo "Done generating icon files."

# Return to the original directory
cd "$original_dir"
