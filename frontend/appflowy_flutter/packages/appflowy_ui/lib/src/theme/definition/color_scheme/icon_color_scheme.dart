import 'package:flutter/material.dart';

class AppFlowyIconColorScheme {
  const AppFlowyIconColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
    required this.infoThick,
    required this.infoThickHover,
    required this.successThick,
    required this.successThickHover,
    required this.warningThick,
    required this.warningThickHover,
    required this.errorThick,
    required this.errorThickHover,
    required this.featuredThick,
    required this.featuredThickHover,
    required this.onFill,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;
  final Color infoThick;
  final Color infoThickHover;
  final Color successThick;
  final Color successThickHover;
  final Color warningThick;
  final Color warningThickHover;
  final Color errorThick;
  final Color errorThickHover;
  final Color featuredThick;
  final Color featuredThickHover;
  final Color onFill;

  AppFlowyIconColorScheme lerp(
    AppFlowyIconColorScheme other,
    double t,
  ) {
    return AppFlowyIconColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      quaternary: Color.lerp(quaternary, other.quaternary, t)!,
      infoThick: Color.lerp(infoThick, other.infoThick, t)!,
      infoThickHover: Color.lerp(infoThickHover, other.infoThickHover, t)!,
      successThick: Color.lerp(successThick, other.successThick, t)!,
      successThickHover:
          Color.lerp(successThickHover, other.successThickHover, t)!,
      warningThick: Color.lerp(warningThick, other.warningThick, t)!,
      warningThickHover:
          Color.lerp(warningThickHover, other.warningThickHover, t)!,
      errorThick: Color.lerp(errorThick, other.errorThick, t)!,
      errorThickHover: Color.lerp(errorThickHover, other.errorThickHover, t)!,
      featuredThick: Color.lerp(featuredThick, other.featuredThick, t)!,
      featuredThickHover:
          Color.lerp(featuredThickHover, other.featuredThickHover, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
    );
  }
}
