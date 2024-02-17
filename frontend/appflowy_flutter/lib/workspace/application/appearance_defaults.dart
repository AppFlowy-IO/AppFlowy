import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

/// A class for the default appearance settings for the app
class DefaultAppearanceSettings {
  static const kDefaultFontFamily = 'Poppins';
  static const kDefaultThemeMode = ThemeMode.system;
  static const kDefaultThemeName = "Default";
  static const kDefaultTheme = BuiltInTheme.defaultTheme;

  static Color getDefaultDocumentCursorColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getDefaultDocumentSelectionColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withOpacity(0.2);
  }
}
