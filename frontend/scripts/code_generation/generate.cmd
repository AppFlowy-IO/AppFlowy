REM Call the script in the 'freezed' folder
echo "Generating files using build_runner"
call freezed\generate.bat

REM Call the script in the 'language_files' folder
echo "Generating files using easy_localization"
call language_files\generate.bat
