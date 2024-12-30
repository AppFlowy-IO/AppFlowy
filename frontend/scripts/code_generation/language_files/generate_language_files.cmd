@echo off

echo 'Generating language files'

REM Store the current working directory
set "original_dir=%CD%"

REM Change the current working directory to the script's location
cd /d "%~dp0"

cd ..\..\..\appflowy_flutter

REM copy the resources/translations folder to
REM   the appflowy_flutter/assets/translation directory
echo Copying resources/translations to appflowy_flutter/assets/translations
xcopy /E /Y /I ..\resources\translations assets\translations

REM call flutter packages pub get
call flutter pub get
call flutter packages pub get

echo Specifying source directory for AppFlowy Localizations.
call dart run easy_localization:generate -S assets/translations/

echo Generating language files for AppFlowy.
call dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json

echo Done generating language files.

REM Return to the original directory
cd /d "%original_dir%"
