#!/bin/bash

# Default values
APP_NAME="AppFlowy"
APP_IDENTIFIER="com.appflowy.appflowy"
COMPANY_NAME="AppFlowy Inc."
COPYRIGHT="Copyright © 2025 AppFlowy Inc."
ICON_PATH=""
WINDOWS_ICON_PATH=""
PLATFORMS=("windows" "linux" "macos" "ios" "android")

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --app-name              Set the application name"
    echo "  --app-identifier        Set the application identifier"
    echo "  --company-name          Set the company name"
    echo "  --copyright             Set the copyright information"
    echo "  --icon-path             Set the path to the application icon (.svg)"
    echo "  --windows-icon-path     Set the path to the windows application icon (.ico)"
    echo "  --platforms             Comma-separated list of platforms to white label (windows,linux,macos,ios,android)"
    echo "  --help                  Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --app-name \"MyCompany\" --app-identifier \"com.mycompany.mycompany\" \\"
    echo "     --company-name \"MyCompany Ltd.\" --copyright \"Copyright © 2025 MyCompany Ltd.\" \\"
    echo "     --platforms \"windows,linux,macos\" \\"
    echo "     --windows-icon-path \"./assets/icons/mycompany.ico\" \\"
    echo "     --icon-path \"./assets/icons/mycompany.svg\""
}

while [[ $# -gt 0 ]]; do
    case $1 in
    --app-name)
        APP_NAME="$2"
        shift 2
        ;;
    --app-identifier)
        APP_IDENTIFIER="$2"
        shift 2
        ;;
    --company-name)
        COMPANY_NAME="$2"
        shift 2
        ;;
    --copyright)
        COPYRIGHT="$2"
        shift 2
        ;;
    --icon-path)
        ICON_PATH="$2"
        shift 2
        ;;
    --windows-icon-path)
        WINDOWS_ICON_PATH="$2"
        shift 2
        ;;
    --platforms)
        IFS=',' read -ra PLATFORMS <<< "$2"
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

if [ -z "$APP_NAME" ] || [ -z "$APP_IDENTIFIER" ] || [ -z "$COMPANY_NAME" ] || [ -z "$COPYRIGHT" ] || [ -z "$ICON_PATH" ]; then
    echo "Error: All parameters are required"
    show_usage
    exit 1
fi

if [ ! -f "$ICON_PATH" ]; then
    echo "Error: Icon file not found at $ICON_PATH"
    exit 1
fi

if [ ! -f "$WINDOWS_ICON_PATH" ]; then
    echo "Error: Windows icon file not found at $WINDOWS_ICON_PATH"
    exit 1
fi

run_platform_script() {
    local platform=$1
    local script_path="scripts/white_label/${platform}_white_label.sh"

    if [ ! -f "$script_path" ]; then
        echo -e "\033[31mWarning: White label script not found for platform: $platform\033[0m"
        return
    fi

    echo -e "\033[32mRunning white label script for $platform...\033[0m"
    bash "$script_path" \
        --app-name "$APP_NAME" \
        --app-identifier "$APP_IDENTIFIER" \
        --company-name "$COMPANY_NAME" \
        --copyright "$COPYRIGHT" \
        --icon-path "$WINDOWS_ICON_PATH"
}

echo -e "\033[32mRunning i18n white label script...\033[0m"
bash "scripts/white_label/i18n_white_label.sh" --company-name "$COMPANY_NAME"

echo -e "\033[32mRunning icon white label script...\033[0m"
bash "scripts/white_label/icon_white_label.sh" --icon-path "$ICON_PATH"

for platform in "${PLATFORMS[@]}"; do
    run_platform_script "$platform"
done

echo -e "\033[32mWhite labeling process completed successfully!\033[0m"
