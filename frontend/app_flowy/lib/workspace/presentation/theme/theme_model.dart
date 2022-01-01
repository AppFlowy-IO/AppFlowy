import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

class ThemeModel extends ChangeNotifier {
  ThemeType _theme = ThemeType.light;

  ThemeType get theme => _theme;

  set theme(ThemeType value) {
    _theme = value;
    notifyListeners();
  }

  void swapTheme() {
    theme = (theme == ThemeType.light ? ThemeType.dark : ThemeType.light);
  }
}
