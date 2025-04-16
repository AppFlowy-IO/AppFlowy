import 'package:appflowy_ui/src/theme/theme.dart';
import 'package:flutter/material.dart';

/// A class that provides a way to access the AppFlowy theme data in the widget
/// tree. We ask [ThemeData] to the dependcy injection for us.
class AppFlowyTheme extends ThemeExtension<AppFlowyTheme> {
  const AppFlowyTheme({required this.themeData});

  static AppFlowyThemeData of(BuildContext context) =>
      Theme.of(context).extension<AppFlowyTheme>()!.themeData;

  static AppFlowyThemeData? maybeOf(BuildContext context) =>
      Theme.of(context).extension<AppFlowyTheme>()?.themeData;

  final AppFlowyThemeData themeData;

  @override
  ThemeExtension<AppFlowyTheme> copyWith({
    AppFlowyThemeData? themeData,
  }) {
    return AppFlowyTheme(
      themeData: themeData ?? this.themeData,
    );
  }

  @override
  ThemeExtension<AppFlowyTheme> lerp(
    covariant ThemeExtension<AppFlowyTheme>? other,
    double t,
  ) {
    if (other is! AppFlowyTheme) {
      return this;
    }
    return AppFlowyTheme(
      themeData: themeData.lerp(other.themeData, t),
    );
  }
}
