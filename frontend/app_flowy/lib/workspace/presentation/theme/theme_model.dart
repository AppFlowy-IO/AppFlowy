import 'package:equatable/equatable.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

class ThemeModel extends ChangeNotifier with EquatableMixin {
  ThemeType _theme = ThemeType.light;

  @override
  List<Object> get props {
    return [_theme];
  }

  ThemeType get theme => _theme;

  set theme(ThemeType value) {
    if (_theme != value) {
      _theme = value;
      notifyListeners();
    }
  }

  void swapTheme() {
    theme = (theme == ThemeType.light ? ThemeType.dark : ThemeType.light);    
  }
}
