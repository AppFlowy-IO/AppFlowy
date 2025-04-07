#!/bin/bash

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --icon-path       Set the path to the application icon (.svg file)"
    echo "  --help            Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --icon-path \"/path/to/new/icon.svg\""
}

NEW_ICON_PATH=""
ICON_DIR="resources/flowy_icons"
ICON_NAME_NEED_REPLACE=("flowy_logo.svg" "flowy_ai_chat_logo.svg")

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

if [ ! -d "$ICON_DIR" ]; then
    echo "Error: Icon directory not found at $ICON_DIR"
    exit 1
fi

echo "Replacing icon..."

echo "Processing icon files..."
for file in $(find "$ICON_DIR" -name "*.svg" -type f); do
    if [[ " ${ICON_NAME_NEED_REPLACE[@]} " =~ " $(basename "$file") " ]]; then
        echo "Updating: $(basename "$file")"

        cp "$NEW_ICON_PATH" "$file"

        if [ $? -eq 0 ]; then
            echo "Successfully replaced $(basename "$file") with new icon"
        else
            echo "Error: Failed to replace $(basename "$file")"
            exit 1
        fi
    fi
done

echo "Replacement complete!"
