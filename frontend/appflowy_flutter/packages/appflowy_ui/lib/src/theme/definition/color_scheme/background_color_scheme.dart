import 'package:flutter/material.dart';

class AppFlowyBackgroundColorScheme {
  const AppFlowyBackgroundColorScheme({
    required this.primary,
  });

  final Color primary;

  AppFlowyBackgroundColorScheme lerp(
    AppFlowyBackgroundColorScheme other,
    double t,
  ) {
    return AppFlowyBackgroundColorScheme(
      primary: Color.lerp(
        primary,
        other.primary,
        t,
      )!,
    );
  }
}
