import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

extension LabelTextPhrasing on ThemeMode {
  String get labelText {
    switch (this) {
      case (ThemeMode.light):
        return LocaleKeys.settings_appearance_themeMode_light.tr();
      case (ThemeMode.dark):
        return LocaleKeys.settings_appearance_themeMode_dark.tr();
      case (ThemeMode.system):
        return LocaleKeys.settings_appearance_themeMode_system.tr();
      default:
        return "";
    }
  }
}

extension ThemeModeExtension on BuildContext {
  ThemeMode get themeMode {
    final brightness = Theme.of(this).brightness;
    return switch (brightness) {
      Brightness.light => ThemeMode.light,
      Brightness.dark => ThemeMode.dark,
    };
  }

  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;
}
