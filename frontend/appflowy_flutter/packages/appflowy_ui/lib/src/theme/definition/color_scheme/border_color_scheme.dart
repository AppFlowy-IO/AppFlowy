import 'package:flutter/material.dart';

class AppFlowyBorderColorScheme {
  AppFlowyBorderColorScheme({
    required this.primary,
    required this.greyPrimary,
    required this.greyPrimaryHover,
    required this.greySecondary,
    required this.greySecondaryHover,
    required this.greyTertiary,
    required this.greyTertiaryHover,
    required this.greyQuaternary,
    required this.greyQuaternaryHover,
    required this.transparent,
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
    required this.purpleThick,
    required this.purpleThickHover,
  });

  final Color primary;
  final Color greyPrimary;
  final Color greyPrimaryHover;
  final Color greySecondary;
  final Color greySecondaryHover;
  final Color greyTertiary;
  final Color greyTertiaryHover;
  final Color greyQuaternary;
  final Color greyQuaternaryHover;
  final Color transparent;
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
  final Color purpleThick;
  final Color purpleThickHover;

  AppFlowyBorderColorScheme lerp(
    AppFlowyBorderColorScheme other,
    double t,
  ) {
    return AppFlowyBorderColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      greyPrimary: Color.lerp(greyPrimary, other.greyPrimary, t)!,
      greyPrimaryHover:
          Color.lerp(greyPrimaryHover, other.greyPrimaryHover, t)!,
      greySecondary: Color.lerp(greySecondary, other.greySecondary, t)!,
      greySecondaryHover:
          Color.lerp(greySecondaryHover, other.greySecondaryHover, t)!,
      greyTertiary: Color.lerp(greyTertiary, other.greyTertiary, t)!,
      greyTertiaryHover:
          Color.lerp(greyTertiaryHover, other.greyTertiaryHover, t)!,
      greyQuaternary: Color.lerp(greyQuaternary, other.greyQuaternary, t)!,
      greyQuaternaryHover:
          Color.lerp(greyQuaternaryHover, other.greyQuaternaryHover, t)!,
      transparent: Color.lerp(transparent, other.transparent, t)!,
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
      purpleThick: Color.lerp(purpleThick, other.purpleThick, t)!,
      purpleThickHover:
          Color.lerp(purpleThickHover, other.purpleThickHover, t)!,
    );
  }
}
