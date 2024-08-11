#!/usr/bin/env bash

# check the cost time
start_time=$(date +%s)

# read the arguments to skip the pub get and package get
skip_pub_get=false
skip_pub_packages_get=false
verbose=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --skip-pub-get)
        skip_pub_get=true
        shift
        ;;
    --skip-pub-packages-get)
        skip_pub_packages_get=true
        shift
        ;;
    --verbose)
        verbose=true
        shift
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# show loading indicator

echo "🚀 Start generating language files."

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
if [ "$skip_pub_get" = false ]; then
    if [ "$verbose" = true ]; then
        flutter pub get
    else
        flutter pub get >/dev/null 2>&1
    fi
fi
if [ "$skip_pub_packages_get" = false ]; then
    if [ "$verbose" = true ]; then
        flutter packages pub get
    else
        flutter packages pub get >/dev/null 2>&1
    fi
fi

if [ "$verbose" = true ]; then
    dart run easy_localization:generate -S assets/translations/
    dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json
else
    dart run easy_localization:generate -S assets/translations/ >/dev/null 2>&1
    dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json >/dev/null 2>&1
fi

echo "🚀 Done generating language files."

# Return to the original directory
cd "$original_dir"

# echo the cost time
end_time=$(date +%s)
cost_time=$((end_time - start_time))
echo "🚀 Language files generation cost $cost_time seconds."
