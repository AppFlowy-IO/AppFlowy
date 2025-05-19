import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

extension DesktopSearchSpecialStyles on BuildContext {
  TextStyle get searchPanelTitle1 {
    return TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: AppFlowyTheme.of(this).textColorScheme.secondary,
    );
  }

  TextStyle get searchPanelTitle2 {
    return TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: AppFlowyTheme.of(this).textColorScheme.primary,
    );
  }

  TextStyle get searchPanelPath {
    return TextStyle(
      fontSize: 12,
      height: 18 / 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: AppFlowyTheme.of(this).textColorScheme.tertiary,
    );
  }
}
