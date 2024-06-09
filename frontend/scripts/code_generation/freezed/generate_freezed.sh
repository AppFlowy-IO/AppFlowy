#!/bin/bash

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

# Navigate to the appflowy_flutter directory and generate files
echo "Generating files for appflowy_flutter"

flutter packages pub get >/dev/null 2>&1

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
    flutter packages pub get >/dev/null 2>&1
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
