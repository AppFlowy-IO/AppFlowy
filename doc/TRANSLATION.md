# TRANSLATION

You can help Appflowy in supporting various languages by contributing. Follow the steps below sequentially to contribute translations.

## Steps to modify an existing translation
Translation files are located in : `frontend/app_flowy/assets/translations/`

1. Modify the specific translation file.
2. Run `flutter pub run easy_localization:generate -S assets/translations/`
3. Run `flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations`
4. Verify that the translation has changed appropriately by compiling and running the app.

## Steps to add new language

**NOTE: Translation files SHOULD be** `json` **files named in the format** `<lang_code>-<country_code>.json` **or just** `<lang_code>.json`**. eg:**`en.json`**,** `en-UK.json`

1. Add language key-value json file to `frontend/app_flowy/assets/translations/`. Refer `en.json` for format and keys.
2. Run `flutter pub run easy_localization:generate -S assets/translations/`
3. Run `flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations`
4. Open the `frontend/app_flowy/lib/startup/tasks/application_widget.dart` file.
5. In the `AppWidgetTask` class, add the locale of the language you just created (eg: `Locale('en', 'IN')`, `Locale('en')`) to the `supportedLocales` List :

  ```dart
  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh_CN')],  // <---- Add locale to this list
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: app),
  );    
  ```
