import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

extension MobileSearchSpecialStylesExtension on BuildContext {
  TextStyle get searchSubtitleStyle {
    return TextStyle(
      fontSize: 16,
      letterSpacing: 0.2,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      color: AppFlowyTheme.of(this).textColorScheme.secondary,
    );
  }

  TextStyle get searchTitleStyle {
    return TextStyle(
      fontSize: 16,
      letterSpacing: 0.2,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: AppFlowyTheme.of(this).textColorScheme.primary,
    );
  }
}
