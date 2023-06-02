#!/bin/sh
#!/usr/bin/env fish
echo 'Generating language files'
cd appflowy_flutter
dart run easy_localization:generate -S assets/translations/
dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations -s en.json
