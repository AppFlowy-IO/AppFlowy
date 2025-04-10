#!/bin/bash

APP_NAME="AppFlowy"
APP_IDENTIFIER="com.appflowy.appflowy"
COMPANY_NAME="AppFlowy Inc."
COPYRIGHT="Copyright © 2025 AppFlowy Inc."
ICON_PATH=""

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
    echo "  $0 --app-name \"MyCompany\" --app-identifier \"com.mycompany.mycompany\" \\"
    echo "     --company-name \"MyCompany Ltd.\" --copyright \"Copyright © 2025 MyCompany Ltd.\" \\"
    echo "     --icon-path \"./assets/icons/company.ico\""
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

if [ -z "$APP_NAME" ]; then
    echo -e "\033[31mError: Application name is required\033[0m"
    exit 1
fi

if [ -z "$APP_IDENTIFIER" ]; then
    echo -e "\033[31mError: Application identifier is required\033[0m"
    exit 1
fi

if [ -z "$COMPANY_NAME" ]; then
    echo -e "\033[31mError: Company name is required\033[0m"
    exit 1
fi

if [ -z "$COPYRIGHT" ]; then
    echo -e "\033[31mError: Copyright information is required\033[0m"
    exit 1
fi

if [ -z "$ICON_PATH" ]; then
    echo -e "\033[31mError: Icon path is required\033[0m"
    exit 1
fi

echo "Starting Windows application customization..."

if sed --version >/dev/null 2>&1; then
    SED_INPLACE="-i"
else
    SED_INPLACE="-i ''"
fi

update_runner_files() {
    runner_dir="appflowy_flutter/windows/runner"

    if [ -f "$runner_dir/Runner.rc" ]; then
        sed $SED_INPLACE "s/VALUE \"CompanyName\", .*$/VALUE \"CompanyName\", \"$COMPANY_NAME\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"FileDescription\", .*$/VALUE \"FileDescription\", \"$APP_NAME\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"InternalName\", .*$/VALUE \"InternalName\", \"$APP_NAME\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"OriginalFilename\", .*$/VALUE \"OriginalFilename\", \"$APP_NAME.exe\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"LegalCopyright\", .*$/VALUE \"LegalCopyright\", \"$COPYRIGHT\"/" "$runner_dir/Runner.rc"
        sed $SED_INPLACE "s/VALUE \"ProductName\", .*$/VALUE \"ProductName\", \"$APP_NAME\"/" "$runner_dir/Runner.rc"
        echo -e "Runner.rc updated successfully"
    else
        echo -e "\033[31mRunner.rc file not found\033[0m"
    fi
}

update_icon() {
    if [ ! -z "$ICON_PATH" ] && [ -f "$ICON_PATH" ]; then
        app_icon_path="appflowy_flutter/windows/runner/resources/app_icon.ico"
        cp "$ICON_PATH" "$app_icon_path"
        echo -e "Application icon updated successfully"
    else
        echo -e "\033[31mApplication icon file not found\033[0m"
    fi
}

update_cmake_lists() {
    cmake_file="appflowy_flutter/windows/CMakeLists.txt"
    if [ -f "$cmake_file" ]; then
        sed $SED_INPLACE "s/set(BINARY_NAME .*)$/set(BINARY_NAME \"$APP_NAME\")/" "$cmake_file"
        echo -e "CMake configuration updated successfully"
    else
        echo -e "\033[31mCMake configuration file not found\033[0m"
    fi
}

update_main_cpp() {
    main_cpp_file="appflowy_flutter/windows/runner/main.cpp"
    if [ -f "$main_cpp_file" ]; then
        sed $SED_INPLACE "s/HANDLE hMutexInstance = CreateMutex(NULL, TRUE, L\"AppFlowyMutex\");/HANDLE hMutexInstance = CreateMutex(NULL, TRUE, L\"${APP_NAME}Mutex\");/" "$main_cpp_file"
        sed $SED_INPLACE "s/HWND handle = FindWindowA(NULL, \"AppFlowy\");/HWND handle = FindWindowA(NULL, \"$APP_NAME\");/" "$main_cpp_file"
        sed $SED_INPLACE "s/if (window.SendAppLinkToInstance(L\"AppFlowy\")) {/if (window.SendAppLinkToInstance(L\"$APP_NAME\")) {/" "$main_cpp_file"
        sed $SED_INPLACE "s/if (!window.Create(L\"AppFlowy\", origin, size)) {/if (!window.Create(L\"$APP_NAME\", origin, size)) {/" "$main_cpp_file"
        echo -e "main.cpp updated successfully"
    else
        echo -e "\033[31mMain.cpp file not found\033[0m"
    fi
}

echo "Applying customizations..."
update_runner_files
update_icon
update_cmake_lists
update_main_cpp

echo "Windows application customization completed successfully!"
