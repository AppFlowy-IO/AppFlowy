import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  chinese,
  italian,
  french,
}

String stringFromLanguage(AppLanguage language) {
  switch (language) {
    case AppLanguage.english:
      return "en";
    case AppLanguage.chinese:
      return "ch";
    case AppLanguage.italian:
      return "it";
    case AppLanguage.french:
      return "fr";
  }
}

string fullStringFromLanguage(AppLanguage language) {
  switch (language) {
    case AppLanguage.english:
      return "english";
    case AppLanguage.chinese:
      return "汉语";
    case AppLanguage.italian:
      return "italiano";
    case AppLanguage.french:
      return "français";
  }
}

AppLanguage languageFromString(String name) {
  AppLanguage language = AppLanguage.english;
  if (name == "ch") {
    language = AppLanguage.chinese;
  } else if (name == "it") {
    language = AppLanguage.italian;
  } else if (name == "fr") {
    language = AppLanguage.french;
  }

  return language;
}

AppLanguage languageFromFullString(String name) {
  AppLanguage language = AppLanguage.english;
  if (name == "汉语") {
    language = AppLanguage.chinese;
  } else if (name == "italiano") {
    language = AppLanguage.italian;
  } else if (name == "français") {
    language = AppLanguage.french;
  }

  return language;
}

Locale localeFromLanguageName(AppLanguage language) {
  switch (language) {
    case AppLanguage.english:
      return const Locale('en');
    case AppLanguage.chinese:
      return const Locale('zh', 'CN');
    case AppLanguage.italian:
      return const Locale('it', 'IT');
    case AppLanguage.french:
      return const Locale('fr', 'CA');
  }
}

AppLanguage languageFromLocale(Locale locale) {
  switch (locale.languageCode) {
    case "zh":
      return AppLanguage.chinese;
    case "it":
      return AppLanguage.italian;
    case "fr":
      return AppLanguage.french;
    default:
      return AppLanguage.english;
  }
}
