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
CODE_FILE="appflowy_flutter/lib/workspace/application/notification/notification_service.dart"

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

if [ ! -f "$CODE_FILE" ]; then
    echo "Error: Code file not found at $CODE_FILE"
    exit 1
fi

echo "Replacing '_localNotifierAppName' value with '$CUSTOM_COMPANY_NAME' in code file..."

if sed --version >/dev/null 2>&1; then
    SED_INPLACE="-i"
else
    SED_INPLACE="-i ''"
fi

echo "Processing code file..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # First, escape any special characters in the company name
    ESCAPED_COMPANY_NAME=$(echo "$CUSTOM_COMPANY_NAME" | sed 's/[\/&]/\\&/g')
    # Replace the _localNotifierAppName value with the custom company name
    sed $SED_INPLACE "s/const _localNotifierAppName = 'AppFlowy'/const _localNotifierAppName = '$ESCAPED_COMPANY_NAME'/" "$CODE_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to process $CODE_FILE with sed"
        exit 1
    fi
else
    # For Unix-like systems
    sed $SED_INPLACE "s/const _localNotifierAppName = 'AppFlowy'/const _localNotifierAppName = '$CUSTOM_COMPANY_NAME'/" "$CODE_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to process $CODE_FILE with sed"
        exit 1
    fi
fi

echo "Replacement complete!"
