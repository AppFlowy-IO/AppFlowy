#!/bin/bash

no_pub_get=false

while getopts 's' flag; do
  case "${flag}" in
  s) no_pub_get=true ;;
  esac
done

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

# Navigate to the appflowy_flutter directory and generate files
echo "Generating files for appflowy_flutter"

if [ "$no_pub_get" = false ]; then
  flutter packages pub get >/dev/null 2>&1
fi

dart run build_runner build -d
echo "Done generating files for appflowy_flutter"

echo "Generating files for packages"
cd packages
for d in */; do
  # Navigate into the subdirectory
  cd "$d"

  # Check if the subdirectory contains a pubspec.yaml file
  if [ -f "pubspec.yaml" ]; then
    echo "Generating freezed files in $d..."
    echo "Please wait while we clean the project and fetch the dependencies."
    if [ "$no_pub_get" = false ]; then
      flutter packages pub get >/dev/null 2>&1
    fi
    dart run build_runner build -d
    echo "Done running build command in $d"
  else
    echo "No pubspec.yaml found in $d, it can\'t be a Dart project. Skipping."
  fi

  # Navigate back to the packages directory
  cd ..
done

# Return to the original directory
cd "$original_dir"
