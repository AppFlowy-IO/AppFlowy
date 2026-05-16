#!/bin/bash

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --icon-path       Set the path to the folder containing application icons (.svg files)"
    echo "  --help            Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --icon-path \"/path/to/icons_folder\""
}

NEW_ICON_PATH=""
ICON_DIR="resources/flowy_icons"
ICON_NAME_NEED_REPLACE=("app_logo.svg" "ai_chat_logo.svg" "app_logo_with_text_light.svg" "app_logo_with_text_dark.svg")

while [[ $# -gt 0 ]]; do
    case $1 in
    --icon-path)
        NEW_ICON_PATH="$2"
        shift 2
        ;;
    --help)
        show_usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
done

if [ -z "$NEW_ICON_PATH" ]; then
    echo "Error: Icon path is required"
    show_usage
    exit 1
fi

if [ ! -d "$NEW_ICON_PATH" ]; then
    echo "Error: New icon directory not found at $NEW_ICON_PATH"
    exit 1
fi

if [ ! -d "$ICON_DIR" ]; then
    echo "Error: Icon directory not found at $ICON_DIR"
    exit 1
fi

echo "Replacing icons..."

echo "Processing icon files..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    for subdir in "${ICON_DIR}"/*/; do
        if [ -d "$subdir" ]; then
            echo "Checking subdirectory: $(basename "$subdir")"
            for file in "${subdir}"*.svg; do
                if [ -f "$file" ] && [[ " ${ICON_NAME_NEED_REPLACE[@]} " =~ " $(basename "$file") " ]]; then
                    new_icon="${NEW_ICON_PATH}/$(basename "$file")"
                    if [ -f "$new_icon" ]; then
                        echo "Updating: $(basename "$subdir")/$(basename "$file")"
                        cp "$new_icon" "$file"
                        if [ $? -eq 0 ]; then
                            echo "Successfully replaced $(basename "$file") in $(basename "$subdir") with new icon"
                        else
                            echo "Error: Failed to replace $(basename "$file") in $(basename "$subdir")"
                            exit 1
                        fi
                    else
                        echo "Warning: New icon file $(basename "$file") not found in $NEW_ICON_PATH"
                    fi
                fi
            done
        fi
    done
else
    for file in $(find "$ICON_DIR" -name "*.svg" -type f); do
        if [[ " ${ICON_NAME_NEED_REPLACE[@]} " =~ " $(basename "$file") " ]]; then
            new_icon="${NEW_ICON_PATH}/$(basename "$file")"
            if [ -f "$new_icon" ]; then
                echo "Updating: $(basename "$file")"
                cp "$new_icon" "$file"
                if [ $? -eq 0 ]; then
                    echo "Successfully replaced $(basename "$file") with new icon"
                else
                    echo "Error: Failed to replace $(basename "$file")"
                    exit 1
                fi
            else
                echo "Warning: New icon file $(basename "$file") not found in $NEW_ICON_PATH"
            fi
        fi
    done
fi

echo "Replacement complete!"
