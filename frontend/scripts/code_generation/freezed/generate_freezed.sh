#!/bin/bash

# Navigate to the appflowy_flutter directory and generate files

echo "Generating files for appflowy_flutter"
cd appflowy_flutter
flutter clean > /dev/null 2>&1 && flutter packages pub get > /dev/null 2>&1 && flutter pub run build_runner build --delete-conflicting-outputs
echo "Done generating files for appflowy_flutter"

echo "Generating files for packages"
cd packages
for d in */ ; do
    # Navigate into the subdirectory
    cd "$d"

    # Check if the subdirectory contains a pubspec.yaml file
    if [ -f "pubspec.yaml" ]; then
        echo "Generating freezed files in $d..."
        echo "Please wait while we clean the project and fetch the dependencies."
        flutter clean > /dev/null 2>&1 && flutter packages pub get > /dev/null 2>&1 && flutter pub run build_runner build
        echo "Done running build command in $d"
    else
        echo "No pubspec.yaml found in $d, it can't be a Dart project. Skipping."
    fi

    # Navigate back to the packages directory
    cd ..
done
