#!/bin/bash

# Windows White Label Script for Flutter Application
# This script helps customize the Windows application build

# Default values
APP_NAME="AppFlowy"
APP_IDENTIFIER="com.appflowy.appflowy"
COMPANY_NAME="AppFlowy Inc."
COPYRIGHT="Copyright © 2025 AppFlowy Inc."
ICON_PATH=""
OUTPUT_DIR="build/windows/runner/Release"

# Function to display usage
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --app-name         Set the application name"
    echo "  --app-identifier   Set the application identifier"
    echo "  --company-name     Set the company name"
    echo "  --copyright        Set the copyright information"
    echo "  --icon-path        Set the path to the application icon (.ico file)"
    echo "  --help            Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --app-name \"MyProduct\" --app-identifier \"com.mycompany.myproduct\" \\"
    echo "     --company-name \"MyCompany Ltd.\" --copyright \"Copyright © 2025 MyCompany Ltd.\" \\"
    echo "     --icon-path \"./assets/icons/myproduct.ico\""
}

# Parse command line arguments
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
    --output-dir)
        OUTPUT_DIR="$2"
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

# Validate required parameters
# 1. APP_NAME
if [ -z "$APP_NAME" ]; then
    echo "Error: Application name is required"
    exit 1
fi

# 2. APP_IDENTIFIER
if [ -z "$APP_IDENTIFIER" ]; then
    echo "Error: Application identifier is required"
    exit 1
fi

# 3. COMPANY_NAME
if [ -z "$COMPANY_NAME" ]; then
    echo "Error: Company name is required"
    exit 1
fi

# 4. COPYRIGHT
if [ -z "$COPYRIGHT" ]; then
    echo "Error: Copyright information is required"
    exit 1
fi

# 5. ICON_PATH
if [ -z "$ICON_PATH" ]; then
    echo "Error: Icon path is required"
    exit 1
fi

echo "Starting Windows application customization..."

# Determine sed in-place syntax for cross-platform compatibility
if sed --version >/dev/null 2>&1; then
    SED_INPLACE="-i"
else
    SED_INPLACE="-i ''"
fi

# Update Runner.rc
update_runner_files() {
    runner_dir="appflowy_flutter/windows/runner"

    # Update Runner.rc with new values
    if [ -f "$runner_dir/Runner.rc" ]; then
        sed $SED_INPLACE "s/VALUE \"CompanyName\", .*$/VALUE \"CompanyName\", \"$COMPANY_NAME\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"FileDescription\", .*$/VALUE \"FileDescription\", \"$APP_NAME\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"InternalName\", .*$/VALUE \"InternalName\", \"$APP_NAME\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"OriginalFilename\", .*$/VALUE \"OriginalFilename\", \"$APP_NAME.exe\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"LegalCopyright\", .*$/VALUE \"LegalCopyright\", \"$COPYRIGHT\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"ProductName\", .*$/VALUE \"ProductName\", \"$APP_NAME\"/" "$runner_dir/Runner.rc"
    fi
}

# Update application icon if provided
update_icon() {
    if [ ! -z "$ICON_PATH" ] && [ -f "$ICON_PATH" ]; then
        runner_dir="appflowy_flutter/windows/runner"
        cp "$ICON_PATH" "$runner_dir/resources/app_icon.ico"
        echo "Application icon updated successfully"
    fi
}

# Update CMake configuration
update_cmake_lists() {
    cmake_file="appflowy_flutter/windows/CMakeLists.txt"
    if [ -f "$cmake_file" ]; then
        sed $SED_INPLACE "s/set(BINARY_NAME .*)$/set(BINARY_NAME \"$APP_NAME\")/" "$cmake_file"
        echo "CMake configuration updated successfully"
    fi
}

# Update main.cpp
update_main_cpp() {
    main_cpp_file="appflowy_flutter/windows/main.cpp"
    if [ -f "$main_cpp_file" ]; then
        # Replace AppFlowy with the custom app name in main.cpp
        sed $SED_INPLACE "s/HANDLE hMutexInstance = CreateMutex(NULL, TRUE, L\"AppFlowyMutex\");/HANDLE hMutexInstance = CreateMutex(NULL, TRUE, L\"${APP_NAME}Mutex\");/" "$main_cpp_file"
        sed $SED_INPLACE "s/HWND handle = FindWindowA(NULL, \"AppFlowy\");/HWND handle = FindWindowA(NULL, \"$APP_NAME\");/" "$main_cpp_file"
        sed $SED_INPLACE "s/if (window.SendAppLinkToInstance(L\"AppFlowy\")) {/if (window.SendAppLinkToInstance(L\"$APP_NAME\")) {/" "$main_cpp_file"
        sed $SED_INPLACE "s/if (!window.Create(L\"AppFlowy\", origin, size)) {/if (!window.Create(L\"$APP_NAME\", origin, size)) {/" "$main_cpp_file"
        echo "Main.cpp updated successfully"
    fi
}

# Execute customization steps
echo "Applying customizations..."
update_runner_files
update_icon
update_cmake_lists
update_main_cpp

echo "Windows application customization completed successfully!"
