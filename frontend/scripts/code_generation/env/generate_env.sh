#!/bin/bash

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

# Navigate to the appflowy_flutter directory and generate files
echo "Generating env files"
# flutter clean >/dev/null 2>&1 && flutter packages pub get >/dev/null 2>&1 && dart run build_runner clean &&
flutter packages pub get >/dev/null 2>&1
dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs
echo "Done generating env files"

# Return to the original directory
cd "$original_dir"
