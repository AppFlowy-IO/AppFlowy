import 'package:flutter/material.dart';

enum Language {
  english,
  chinese,
  italian,
  french,
}

String stringFromLanguageName(Language language) {
  switch (language) {
    case Language.english:
      return "en";
    case Language.chinese:
      return "ch";
    case Language.italian:
      return "it";
    case Language.french:
      return "fr";
  }
}

Language languageFromString(String name) {
  Language language = Language.english;
  if (name == "ch") {
    language = Language.chinese;
  } else if (name == "it") {
    language = Language.italian;
  } else if (name == "fr") {
    language = Language.french;
  }

  return language;
}

Locale localeFromLanguageName(Language language) {
  switch (language) {
    case Language.english:
      return const Locale('en');
    case Language.chinese:
      return const Locale('zh', 'CN');
    case Language.italian:
      return const Locale('it', 'IT');
    case Language.french:
      return const Locale('fr', 'CA');
  }
}

class AppLanguage {
  Locale locale;

  //Default Constructor
  AppLanguage({required this.locale});

  factory AppLanguage.fromLanguage({required Language language}) {
    return AppLanguage(locale: localeFromLanguageName(language));
  }

  factory AppLanguage.fromName({required String name}) {
    return AppLanguage.fromLanguage(language: languageFromString(name));
  }
}
