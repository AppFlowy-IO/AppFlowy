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
    case "am":
      return "አማርኛ";
    case "ar":
      return "العربية";
    case "ca":
      return "Català";
    case "cs":
      return "Čeština";
    case "ckb":
      switch (locale.countryCode) {
        case "KU":
          return "کوردی سۆرانی";
        default:
          return locale.languageCode;
      }
    case "de":
      return "Deutsch";
    case "es":
      return "Español";
    case "eu":
      return "Euskera";
    case "el":
      return "Ελληνικά";
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
    case "th":
      return "ไทย";
    case "tr":
      return "Türkçe";
    case "fa":
      return "فارسی";
    case "uk":
      return "українська";
    case "ur":
      return "اردو";
    case "hin":
      return "हिन्दी";
  }
  // If not found then the language code will be displayed
  return locale.languageCode;
}
