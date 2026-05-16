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
    # Check if directory exists and has JSON files
    if [ ! -d "$I18N_DIR" ] || [ -z "$(ls -A "$I18N_DIR"/*.json 2>/dev/null)" ]; then
        echo "Error: No JSON files found in $I18N_DIR directory"
        exit 1
    fi

    # Process each JSON file in the directory
    for file in "$I18N_DIR"/*.json; do
        echo "Updating $(basename "$file")"
        # Use jq to replace AppFlowy with custom company name in values only
        if command -v jq >/dev/null 2>&1; then
            # Create a temporary file for the transformation
            jq --arg company "$CUSTOM_COMPANY_NAME" 'walk(if type == "string" then gsub("AppFlowy"; $company) else . end)' "$file" > "${file}.tmp"
            # Check if transformation was successful
            if [ $? -eq 0 ]; then
                mv "${file}.tmp" "$file"
            else
                echo "Error: Failed to process $file with jq"
                rm -f "${file}.tmp"
                exit 1
            fi
        else
            # Fallback to sed if jq is not available
            # First, escape any special characters in the company name
            ESCAPED_COMPANY_NAME=$(echo "$CUSTOM_COMPANY_NAME" | sed 's/[\/&]/\\&/g')
            # Replace AppFlowy with the custom company name in JSON values
            sed $SED_INPLACE 's/\(".*"\): *"\(.*\)AppFlowy\(.*\)"/\1: "\2'"$ESCAPED_COMPANY_NAME"'\3"/g' "$file"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to process $file with sed"
                exit 1
            fi
        fi
    done
else
    for file in $(find "$I18N_DIR" -name "*.json" -type f); do
        echo "Updating $(basename "$file")"
        # Use jq to only replace values, not keys
        if command -v jq >/dev/null 2>&1; then
            jq 'walk(if type == "string" then gsub("AppFlowy"; "'"$CUSTOM_COMPANY_NAME"'") else . end)' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        else
            # Fallback to sed with a more specific pattern that targets values but not keys
            sed $SED_INPLACE 's/: *"[^"]*AppFlowy[^"]*"/: "&"/g; s/: *"&"/: "'"$CUSTOM_COMPANY_NAME"'"/g' "$file"
            # Fix any double colons that might have been introduced
            sed $SED_INPLACE 's/: *: */: /g' "$file"
        fi
    done
fi

echo "Replacement complete!"
