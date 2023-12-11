import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

extension LabelTextPhrasing on ThemeMode {
  String get labelText => switch (this) {
        ThemeMode.light => LocaleKeys.settings_appearance_themeMode_light.tr(),
        ThemeMode.dark => LocaleKeys.settings_appearance_themeMode_dark.tr(),
        ThemeMode.system =>
          LocaleKeys.settings_appearance_themeMode_system.tr(),
      };
}
