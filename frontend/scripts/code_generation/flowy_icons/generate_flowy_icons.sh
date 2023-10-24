#!/bin/bash

no_pub_get=false

while getopts 's' flag; do
  case "${flag}" in
    s) no_pub_get=true ;;
  esac
done

echo "Generating flowy icon files"

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

rm -rf assets/flowy_icons/
mkdir -p assets/flowy_icons/
rsync -r ../resources/flowy_icons/ assets/flowy_icons/

if [ "$no_pub_get" = false ]; then
  flutter packages pub get
fi

echo "Generating FlowySvg classes"
dart run flowy_svg

echo "Done generating icon files."

# Return to the original directory
cd "$original_dir"
