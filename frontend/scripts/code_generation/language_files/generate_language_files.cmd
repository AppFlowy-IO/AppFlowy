@echo off
setlocal enabledelayedexpansion

REM Store the current working directory
set "original_dir=%CD%"

REM Change the current working directory to the script's location
cd /d "%~dp0"

REM Define default source and destination directories
set "resources_dir=..\resources\translations"
set "flutter_project_dir=..\..\..\appflowy_flutter"
set "assets_dir=%flutter_project_dir%\assets\translations"

REM Check if required dependencies are available
where flutter > nul 2>&1 || (
  echo Error: Flutter not found in PATH.
  exit /b 1
)

where dart > nul 2>&1 || (
  echo Error: Dart not found in PATH.
  exit /b 1
)

REM Process command-line arguments for source and destination directories
if "%~1" neq "" set "resources_dir=%~1"
if "%~2" neq "" set "assets_dir=%~2"

REM Ensure that source and destination directories end with a backslash
if "%resources_dir:~-1%" neq "\" set "resources_dir=%resources_dir%\"
if "%assets_dir:~-1%" neq "\" set "assets_dir=%assets_dir%\"

flutter packages pub get

REM Copy the resources/translations folder to the appflowy_flutter/assets/translations directory
echo Copying %resources_dir% to %assets_dir%
xcopy /E /Y /I "%resources_dir%" "%assets_dir%"

echo Specifying source directory for AppFlowy Localizations.
dart run easy_localization:generate -S %assets_dir%

echo Generating language files for AppFlowy.
dart run easy_localization:generate -f keys -o %flutter_project_dir%\locale_keys.g.dart -S %assets_dir% -s en.json

echo Done generating language files.

REM Return to the original directory
cd /d "%original_dir%"

endlocal
