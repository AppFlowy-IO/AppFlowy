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
echo "Generating env files"
if [ "$no_pub_get" = false ]; then
  flutter packages pub get >/dev/null 2>&1
fi
dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs
echo "Done generating env files"

# Return to the original directory
cd "$original_dir"
