import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';

class ThemeProvider extends ChangeNotifier {
  // ThemeMode themeMode = ThemeMode.system;
  ThemeMode themeMode = ThemeMode.system;

  // Theme themeMode = Theme.of(context);
  bool _darkMode = false;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  void ThemeNotify() {
    _darkMode = true;
  }

  // bool set isDarkMode => _darkMode;

  void toggleTheme(bool isOn) {
    // _darkMode = !_darkMode;
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class ThemeSwitch {
  // static final darkTheme = AppTheme.fromType(ThemeType.dark);

  // static final lightTheme = AppTheme.fromType(ThemeType.light);

  static final dark = AppTheme.fromType(ThemeType.dark).themeData;

  static final light = AppTheme.fromType(ThemeType.light).themeData;
}
