#!/bin/bash

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --company-name     Set the custom company name"
    echo "  --help            Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --company-name \"MyCompany Ltd.\""
}

CUSTOM_COMPANY_NAME=""
I18N_DIR="resources/translations"

while [[ $# -gt 0 ]]; do
    case $1 in
    --company-name)
        CUSTOM_COMPANY_NAME="$2"
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

if [ -z "$CUSTOM_COMPANY_NAME" ]; then
    echo "Error: Company name is required"
    show_usage
    exit 1
fi

if [ ! -d "$I18N_DIR" ]; then
    echo "Error: Translation directory not found at $I18N_DIR"
    exit 1
fi

echo "Replacing 'AppFlowy' with '$CUSTOM_COMPANY_NAME' in translation files..."

if sed --version >/dev/null 2>&1; then
    SED_INPLACE="-i"
else
    SED_INPLACE="-i ''"
fi

echo "Processing translation files..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    for file in "$I18N_DIR"/*.json; do
        if [ -f "$file" ]; then
            echo "Updating: $(basename "$file")"
            sed -i "s/AppFlowy/$CUSTOM_COMPANY_NAME/g" "$file"
        fi
    done
else
    for file in $(find "$I18N_DIR" -name "*.json" -type f); do
        echo "Updating: $(basename "$file")"
        sed $SED_INPLACE "s/AppFlowy/$CUSTOM_COMPANY_NAME/g" "$file"
    done
fi

echo "Replacement complete!"
