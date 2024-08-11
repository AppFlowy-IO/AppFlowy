#!/usr/bin/env bash

args=("$@")

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

# Store the current working directory
original_dir=$(pwd)

# Change the current working directory to the script's location
cd "$(dirname "$0")"

# Call the script in the 'language_files' folder
cd language_files
# Allow execution permissions on CI
chmod +x ./generate_language_files.sh
# Pass the arguments to the script
./generate_language_files.sh "${args[@]}"

# # Return to the main script directory
# cd ..

# # Call the script in the 'freezed' folder
# cd freezed
# # Allow execution permissions on CI
# chmod +x ./generate_freezed.sh
# ./generate_freezed.sh "$@"

# # Return to the main script directory
# cd ..

# # Call the script in the 'flowy_icons' folder
# cd flowy_icons
# # Allow execution permissions on CI
# chmod +x ./generate_flowy_icons.sh
# ./generate_flowy_icons.sh "$@"

# Return to the original directory
cd "$original_dir"

# echo the cost time
end_time=$(date +%s)
cost_time=$((end_time - start_time))
echo "✅ Code generation cost $cost_time seconds."
