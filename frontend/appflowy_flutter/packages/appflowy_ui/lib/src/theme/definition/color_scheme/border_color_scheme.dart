import 'package:flutter/material.dart';

class AppFlowyBorderColorScheme {
  const AppFlowyBorderColorScheme({
    required this.primary,
    required this.primaryHover,
    required this.secondary,
    required this.secondaryHover,
    required this.tertiary,
    required this.tertiaryHover,
    required this.themeThick,
    required this.themeThickHover,
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
  });

  final Color primary;
  final Color primaryHover;
  final Color secondary;
  final Color secondaryHover;
  final Color tertiary;
  final Color tertiaryHover;
  final Color themeThick;
  final Color themeThickHover;
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

  AppFlowyBorderColorScheme lerp(
    AppFlowyBorderColorScheme other,
    double t,
  ) {
    return AppFlowyBorderColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryHover: Color.lerp(secondaryHover, other.secondaryHover, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryHover: Color.lerp(tertiaryHover, other.tertiaryHover, t)!,
      themeThick: Color.lerp(themeThick, other.themeThick, t)!,
      themeThickHover: Color.lerp(themeThickHover, other.themeThickHover, t)!,
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
    );
  }
}
