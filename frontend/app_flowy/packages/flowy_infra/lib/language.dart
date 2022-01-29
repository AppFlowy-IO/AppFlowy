import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  chinese,
  italian,
  french,
}

String stringFromLanguageName(AppLanguage language) {
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
