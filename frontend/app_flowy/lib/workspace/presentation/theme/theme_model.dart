import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

class ThemeModel extends ChangeNotifier {
  ThemeType get theme => _theme;
  ThemeType _theme = ThemeType.light;

  set theme(ThemeType value) {
    _theme = value;
    notifyListeners();
  }

  void swapTheme() {
    theme = (theme == ThemeType.light ? ThemeType.dark : ThemeType.light);
  }
}
