@echo off

echo 'Generating language files'

REM Store the current working directory
set "original_dir=%CD%"

REM Change the current working directory to the script's location
cd /d "%~dp0"

cd ..\..\..\appflowy_flutter

call flutter clean

call flutter packages pub get

echo Specifying source directory for AppFlowy Localizations.
call dart run easy_localization:generate -S assets/translations/

echo Generating language files for AppFlowy.
call dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json

echo Done generating language files.

REM Return to the original directory
cd /d "%original_dir%"
