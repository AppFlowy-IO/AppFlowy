# TRANSLATION

You can help Appflowy in supporting various languages by contributing. Follow the steps below sequentially to contribute translations.

**NOTE: Translation files SHOULD be** `json` **files named in the format** `<lang_code>-<country_code>.json` **or just** `<lang_code>.json`**. eg:**`en.json`**,** `en-UK.json`

## Steps to add new language support

1. Add language key-value json file to `frontend/app_flowy/assets/translations/`. Refer `en.json` for format and keys.
2. Run `flutter pub run easy_localization:generate -S assets/translations/`.
3. Run `flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations`.
4. Add locale of the language (eg: `Locale('en', 'IN')`, `Locale('en')`) in `supportedLocales` list under `EasyLocalization` wrapper for flutter to support it.
This is located in `frontend/app_flowy/lib/startup/tasks/application_widget.dart` under `AppWidgetTask` class as shown below:

    ```dart
    runApp(
      EasyLocalization(
          supportedLocales: const [ Locale('en') ], // <---- Add locale to this list
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: app),
    );
    ```

## Steps to modify translations

1. Modify the specific translation file.
2. Run `flutter pub run easy_localization:generate -S assets/translations/`.
3. Run `flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S assets/translations`.
