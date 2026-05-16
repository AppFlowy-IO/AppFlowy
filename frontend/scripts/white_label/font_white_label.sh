#!/bin/bash

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --font-path       Set the path to the folder containing font files (.ttf or .otf files)"
    echo "  --font-family     Set the name of the font family"
    echo "  --help            Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --font-path \"/path/to/fonts\" --font-family \"CustomFont\""
}

FONT_PATH=""
FONT_FAMILY=""
TARGET_FONT_DIR="appflowy_flutter/assets/fonts/"
PUBSPEC_FILE="appflowy_flutter/pubspec.yaml"
BASE_APPEARANCE_FILE="appflowy_flutter/lib/workspace/application/settings/appearance/base_appearance.dart"

while [[ $# -gt 0 ]]; do
    case $1 in
    --font-path)
        FONT_PATH="$2"
        shift 2
        ;;
    --font-family)
        FONT_FAMILY="$2"
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

# Validate required arguments
if [ -z "$FONT_PATH" ]; then
    echo "Error: Font path is required"
    show_usage
    exit 1
fi

if [ -z "$FONT_FAMILY" ]; then
    echo "Error: Font family name is required"
    show_usage
    exit 1
fi

# Check if source directory exists
if [ ! -d "$FONT_PATH" ]; then
    echo "Error: Font directory not found at $FONT_PATH"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET_FONT_DIR"

# Clean existing fonts in target directory
echo "Cleaning existing fonts in $TARGET_FONT_DIR..."
rm -rf "$TARGET_FONT_DIR"/*

# Copy font files to target directory
echo "Copying font files from $FONT_PATH to $TARGET_FONT_DIR..."
found_fonts=false
for ext in ttf otf; do
    if ls "$FONT_PATH"/*."$ext" >/dev/null 2>&1; then
        cp "$FONT_PATH"/*."$ext" "$TARGET_FONT_DIR"/ 2>/dev/null && found_fonts=true
    fi
done

if [ "$found_fonts" = false ]; then
    echo "Error: No font files (.ttf or .otf) found in source directory"
    exit 1
fi

# Generate font configuration for pubspec.yaml
echo "Generating font configuration..."

# Create temporary file for font configuration
TEMP_FILE=$(mktemp)

{
    echo "    # BEGIN: WHITE_LABEL_FONT"
    echo "    - family: $FONT_FAMILY"
    echo "      fonts:"

    # Generate entries for each font file
    for font_file in "$TARGET_FONT_DIR"/*; do
        filename=$(basename "$font_file")
        echo "        - asset: assets/fonts/$filename"

        # Try to detect font weight from filename
        if [[ $filename =~ (Thin|ExtraLight|Light|Regular|Medium|SemiBold|Bold|ExtraBold|Black) ]]; then
            case ${BASH_REMATCH[1]} in
                "Thin") echo "          weight: 100";;
                "ExtraLight") echo "          weight: 200";;
                "Light") echo "          weight: 300";;
                "Regular") echo "          weight: 400";;
                "Medium") echo "          weight: 500";;
                "SemiBold") echo "          weight: 600";;
                "Bold") echo "          weight: 700";;
                "ExtraBold") echo "          weight: 800";;
                "Black") echo "          weight: 900";;
            esac
        fi

        # Try to detect italic style from filename
        if [[ $filename =~ Italic ]]; then
            echo "          style: italic"
        fi
    done
    echo "    # END: WHITE_LABEL_FONT"
} > "$TEMP_FILE"

# Update pubspec.yaml
echo "Updating pubspec.yaml..."
if [ -f "$PUBSPEC_FILE" ]; then
    # Create a backup of the original file
    cp "$PUBSPEC_FILE" "${PUBSPEC_FILE}.bak"

    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows-specific handling
        # First, remove existing white label font configuration
        awk '/# BEGIN: WHITE_LABEL_FONT/,/# END: WHITE_LABEL_FONT/{ next } /# White-label font configuration will be added here/{ print; system("cat '"$TEMP_FILE"'"); next } 1' "$PUBSPEC_FILE" > "${PUBSPEC_FILE}.tmp"

        if [ $? -eq 0 ]; then
            mv "${PUBSPEC_FILE}.tmp" "$PUBSPEC_FILE"
            rm -f "${PUBSPEC_FILE}.bak"
        else
            echo "Error: Failed to update pubspec.yaml"
            mv "${PUBSPEC_FILE}.bak" "$PUBSPEC_FILE"
            rm -f "${PUBSPEC_FILE}.tmp"
            rm -f "$TEMP_FILE"
            exit 1
        fi
    else
        # Unix-like systems handling
        if sed --version >/dev/null 2>&1; then
            SED_INPLACE="-i"
        else
            SED_INPLACE="-i ''"
        fi

        # Remove existing white label font configuration
        sed $SED_INPLACE '/# BEGIN: WHITE_LABEL_FONT/,/# END: WHITE_LABEL_FONT/d' "$PUBSPEC_FILE"

        # Add new font configuration
        sed $SED_INPLACE "/# White-label font configuration will be added here/r $TEMP_FILE" "$PUBSPEC_FILE"

        if [ $? -ne 0 ]; then
            echo "Error: Failed to update pubspec.yaml"
            mv "${PUBSPEC_FILE}.bak" "$PUBSPEC_FILE"
            rm -f "$TEMP_FILE"
            exit 1
        fi
        rm -f "${PUBSPEC_FILE}.bak"
    fi
else
    echo "Error: pubspec.yaml not found at $PUBSPEC_FILE"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Update base_appearance.dart
echo "Updating base_appearance.dart..."
if [ -f "$BASE_APPEARANCE_FILE" ]; then
    # Create a backup of the original file
    cp "$BASE_APPEARANCE_FILE" "${BASE_APPEARANCE_FILE}.bak"

    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows-specific handling
        sed -i "s/const defaultFontFamily = '.*'/const defaultFontFamily = '$FONT_FAMILY'/" "$BASE_APPEARANCE_FILE"
    else
        # Unix-like systems handling
        sed -i '' "s/const defaultFontFamily = '.*'/const defaultFontFamily = '$FONT_FAMILY'/" "$BASE_APPEARANCE_FILE"
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to update base_appearance.dart"
        mv "${BASE_APPEARANCE_FILE}.bak" "$BASE_APPEARANCE_FILE"
        exit 1
    fi
    rm -f "${BASE_APPEARANCE_FILE}.bak"
else
    echo "Error: base_appearance.dart not found at $BASE_APPEARANCE_FILE"
    exit 1
fi

# Cleanup
rm -f "$TEMP_FILE"

echo "Font white labeling completed successfully!"
