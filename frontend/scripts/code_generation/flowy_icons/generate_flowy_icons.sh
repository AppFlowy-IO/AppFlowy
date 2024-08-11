#!/usr/bin/env bash

# check the cost time
start_time=$(date +%s)

# read the arguments to skip the pub get and package get
skip_pub_get=false
skip_pub_packages_get=false
verbose=false
include_packages=false

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
    --include-packages)
        shift
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "🖼️ Start generating image/svg files"

# Store the current working directory
original_dir=$(pwd)

cd "$(dirname "$0")"

# Navigate to the project root
cd ../../../appflowy_flutter

rm -rf assets/flowy_icons/
mkdir -p assets/flowy_icons/
rsync -r ../resources/flowy_icons/ assets/flowy_icons/

if [ "$skip_pub_get" = false ]; then
    if [ "$verbose" = true ]; then
        flutter pub get
    else
        flutter pub get >/dev/null 2>&1
    fi
fi

if [ "$include_packages" = true ]; then
    if [ "$verbose" = true ]; then
        flutter packages pub get
    else
        flutter packages pub get >/dev/null 2>&1
    fi
fi

if [ "$verbose" = true ]; then
    dart run flowy_svg
else
    dart run flowy_svg >/dev/null 2>&1
fi

# Return to the original directory
cd "$original_dir"

echo "🖼️ Done generating image/svg files."

# echo the cost time
end_time=$(date +%s)
cost_time=$((end_time - start_time))
echo "🖼️ Image/svg files generation cost $cost_time seconds."
