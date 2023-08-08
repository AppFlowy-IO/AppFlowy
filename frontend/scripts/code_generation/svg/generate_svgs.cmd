@echo off

echo 'Generating svg files'

REM Store the current working directory
set "original_dir=%CD%"

REM Change the current working directory to the script's location
cd /d "%~dp0"

cd ..\..\..\appflowy_flutter

call flutter packages pub get

call dart run flowy_svg

echo Done generating svg files.

REM Return to the original directory
cd /d "%original_dir%"
