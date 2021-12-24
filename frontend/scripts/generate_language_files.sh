#!/bin/sh
#!/usr/bin/env fish
echo 'Generating language files'
cd app_flowy
flutter pub run easy_localization:generate -S assets/translations/
flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations
