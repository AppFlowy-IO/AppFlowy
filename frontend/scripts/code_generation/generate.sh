#!/bin/bash

# Call the script in the 'freezed' folder
echo "Generating files using build_runner"
./freezed/generate_freezed.sh "$@"

# Call the script in the 'language_files' folder
echo "Generating files using easy_localization"
./language_files/generate_language_files.sh "$@"
