#!/bin/sh
#!/usr/bin/env fish
echo 'Generating language files'
cd appflowy_flutter
flutter pub run easy_localization:generate -S assets/translations/
flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations -s en.json
