@echo off

REM Navigate to the appflowy_flutter directory and generate files

echo Generating files for appflowy_flutter
cd appflowy_flutter
call flutter clean >nul 2>&1 && call flutter packages pub get >nul 2>&1 && call flutter pub run build_runner build --delete-conflicting-outputs
echo Done generating files for appflowy_flutter

echo Generating files for packages
cd packages
for /D %%d in (*) do (
    REM Navigate into the subdirectory
    cd "%%d"

    REM Check if the subdirectory contains a pubspec.yaml file
    if exist "pubspec.yaml" (
        echo Generating freezed files in %%d...
        echo Please wait while we clean the project and fetch the dependencies.
        call flutter clean >nul 2>&1 && call flutter packages pub get >nul 2>&1 && call flutter pub run build_runner build
        echo Done running build command in %%d
    ) else (
        echo No pubspec.yaml found in %%d, it can't be a Dart project. Skipping.
    )

    REM Navigate back to the packages directory
    cd ..
)
