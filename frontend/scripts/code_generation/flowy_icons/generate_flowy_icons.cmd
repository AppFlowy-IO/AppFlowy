@echo off

echo 'Generating flowy icon files'

REM Store the current working directory
set "original_dir=%CD%"

REM Change the current working directory to the script's location
cd /d "%~dp0"

cd ..\..\..\appflowy_flutter

REM copy the resources/translations folder to
REM   the appflowy_flutter/assets/translation directory
echo Copying resources/flowy_icons to appflowy_flutter/assets/flowy_icons
xcopy /E /Y /I ..\resources\flowy_icons assets\flowy_icons

REM call flutter packages pub get

echo Generating FlowySvg class
call dart run flowy_svg

echo Done generating icon files.

REM Return to the original directory
cd /d "%original_dir%"
