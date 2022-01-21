echo 'Generating language files'
cd app_flowy

call flutter pub run easy_localization:generate -S assets/translations/
call flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations/ -s en.json