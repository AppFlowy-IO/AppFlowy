@echo off

REM Store the current working directory
set "original_dir=%CD%"

REM Change the current working directory to the script's location
cd /d "%~dp0"

REM Navigate to the project root
cd ..\..\..\appflowy_flutter

REM Navigate to the appflowy_flutter directory and generate files
echo Generating env files
call flutter packages pub get >nul 2>&1 && call dart run build_runner clean && call dart run build_runner build --delete-conflicting-outputs
echo Done generating env files

cd /d "%original_dir%"
