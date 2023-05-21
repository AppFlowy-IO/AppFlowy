import 'package:flutter/material.dart';

String languageFromLocale(Locale locale) {
  switch (locale.languageCode) {
    // Most often used languages
    case "en":
      return "English";
    case "zh":
      switch (locale.countryCode) {
        case "CN":
          return "简体中文";
        case "TW":
          return "繁體中文";
        default:
          return locale.languageCode;
      }

    // Then in alphabetical order
    case "ar":
      return "العربية";
    case "ca":
      return "Català";
    case "de":
      return "Deutsch";
    case "es":
      return "Español";
    case "eu":
      return "Euskera";
    case "fr":
      switch (locale.countryCode) {
        case "CA":
          return "Français (CA)";
        case "FR":
          return "Français (FR)";
        default:
          return locale.languageCode;
      }
    case "hu":
      return "Magyar";
    case "id":
      return "Bahasa Indonesia";
    case "it":
      return "Italiano";
    case "ja":
      return "日本語";
    case "ko":
      return "한국어";
    case "pl":
      return "Polski";
    case "pt":
      return "Português";
    case "ru":
      return "русский";
    case "sv":
      return "Svenska";
    case "tr":
      return "Türkçe";

    // If not found then the language code will be displayed
    default:
      return locale.languageCode;
  }
}
