import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

/// A class for the default appearance settings for the app
class DefaultAppearanceSettings {
  static const kDefaultFontFamily = defaultFontFamily;
  static const kDefaultThemeMode = ThemeMode.system;
  static const kDefaultThemeName = "Default";
  static const kDefaultTheme = BuiltInTheme.defaultTheme;

  static Color getDefaultCursorColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getDefaultSelectionColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
  }
}
