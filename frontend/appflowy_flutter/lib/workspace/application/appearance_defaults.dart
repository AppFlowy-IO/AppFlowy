import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

/// A class for the default appearance settings for the app
class DefaultAppearanceSettings {
  static const kDefaultFontFamily = 'Poppins';
  static const kDefaultThemeMode = ThemeMode.system;
  static const kDefaultThemeName = "Default";
  static const kDefaultTheme = BuiltInTheme.defaultTheme;
  // same color as the default color in appflowy_eidtor package
  static const kDefaultDocumentCursorColor = Color(0xFF00BCF0);
  static const kDefaultDocumentSelectionColor =
      Color.fromARGB(53, 111, 201, 231);
}
