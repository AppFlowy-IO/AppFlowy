echo 'Generating language files'
cd appflowy_flutter

call dart run easy_localization:generate -S assets/translations/
call dart run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json