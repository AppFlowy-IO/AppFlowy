import 'package:flutter/material.dart';

class AppFlowyBackgroundColorScheme {
  const AppFlowyBackgroundColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;

  AppFlowyBackgroundColorScheme lerp(
    AppFlowyBackgroundColorScheme other,
    double t,
  ) {
    return AppFlowyBackgroundColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      quaternary: Color.lerp(quaternary, other.quaternary, t)!,
    );
  }
}
