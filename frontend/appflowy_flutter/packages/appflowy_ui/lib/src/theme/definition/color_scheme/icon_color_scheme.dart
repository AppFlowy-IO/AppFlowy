import 'package:flutter/material.dart';

class AppFlowyIconColorScheme {
  const AppFlowyIconColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
    required this.white,
    required this.purpleThick,
    required this.purpleThickHover,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;
  final Color white;
  final Color purpleThick;
  final Color purpleThickHover;

  AppFlowyIconColorScheme lerp(
    AppFlowyIconColorScheme other,
    double t,
  ) {
    return AppFlowyIconColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      quaternary: Color.lerp(quaternary, other.quaternary, t)!,
      white: Color.lerp(white, other.white, t)!,
      purpleThick: Color.lerp(purpleThick, other.purpleThick, t)!,
      purpleThickHover:
          Color.lerp(purpleThickHover, other.purpleThickHover, t)!,
    );
  }
}
