@echo off

REM Store the current working directory
set "original_dir=%CD%"

REM Change the current working directory to the script's location
cd /d "%~dp0"

REM Navigate to the project root
cd ..\..\..\appflowy_flutter

REM Navigate to the appflowy_flutter directory and generate files
echo Generating files for appflowy_flutter
REM call flutter packages pub get
call flutter packages pub get
call dart run build_runner clean && call dart run build_runner build -d
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
        call dart run build_runner clean && call dart run build_runner build -d
        echo Done running build command in %%d
    ) else (
        echo No pubspec.yaml found in %%d, it can't be a Dart project. Skipping.
    )

    REM Navigate back to the packages directory
    cd ..
)

REM Return to the original directory
cd /d "%original_dir%"
