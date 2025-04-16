import 'package:flutter/material.dart';

class AppFlowyFillColorScheme {
  const AppFlowyFillColorScheme({
    required this.primary,
    required this.primaryHover,
    required this.secondary,
    required this.secondaryHover,
    required this.tertiary,
    required this.tertiaryHover,
    required this.quaternary,
    required this.quaternaryHover,
    required this.transparent,
    required this.primaryAlpha5,
    required this.primaryAlpha5Hover,
    required this.primaryAlpha80,
    required this.primaryAlpha80Hover,
    required this.white,
    required this.whiteAlpha,
    required this.whiteAlphaHover,
    required this.black,
    required this.themeLight,
    required this.themeLightHover,
    required this.themeThick,
    required this.themeThickHover,
    required this.themeSelect,
    required this.infoLight,
    required this.infoLightHover,
    required this.infoThick,
    required this.infoThickHover,
    required this.successLight,
    required this.successLightHover,
    required this.successThick,
    required this.successThickHover,
    required this.warningLight,
    required this.warningLightHover,
    required this.warningThick,
    required this.warningThickHover,
    required this.errorLight,
    required this.errorLightHover,
    required this.errorThick,
    required this.errorThickHover,
    required this.errorSelect,
    required this.purpleLight,
    required this.purpleLightHover,
    required this.purpleThick,
    required this.purpleThickHover,
  });

  final Color primary;
  final Color primaryHover;
  final Color secondary;
  final Color secondaryHover;
  final Color tertiary;
  final Color tertiaryHover;
  final Color quaternary;
  final Color quaternaryHover;
  final Color transparent;
  final Color primaryAlpha5;
  final Color primaryAlpha5Hover;
  final Color primaryAlpha80;
  final Color primaryAlpha80Hover;
  final Color white;
  final Color whiteAlpha;
  final Color whiteAlphaHover;
  final Color black;
  final Color themeLight;
  final Color themeLightHover;
  final Color themeThick;
  final Color themeThickHover;
  final Color themeSelect;
  final Color infoLight;
  final Color infoLightHover;
  final Color infoThick;
  final Color infoThickHover;
  final Color successLight;
  final Color successLightHover;
  final Color successThick;
  final Color successThickHover;
  final Color warningLight;
  final Color warningLightHover;
  final Color warningThick;
  final Color warningThickHover;
  final Color errorLight;
  final Color errorLightHover;
  final Color errorThick;
  final Color errorThickHover;
  final Color errorSelect;
  final Color purpleLight;
  final Color purpleLightHover;
  final Color purpleThick;
  final Color purpleThickHover;

  AppFlowyFillColorScheme lerp(
    AppFlowyFillColorScheme other,
    double t,
  ) {
    return AppFlowyFillColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryHover: Color.lerp(secondaryHover, other.secondaryHover, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryHover: Color.lerp(tertiaryHover, other.tertiaryHover, t)!,
      quaternary: Color.lerp(quaternary, other.quaternary, t)!,
      quaternaryHover: Color.lerp(quaternaryHover, other.quaternaryHover, t)!,
      transparent: Color.lerp(transparent, other.transparent, t)!,
      primaryAlpha5: Color.lerp(primaryAlpha5, other.primaryAlpha5, t)!,
      primaryAlpha5Hover:
          Color.lerp(primaryAlpha5Hover, other.primaryAlpha5Hover, t)!,
      primaryAlpha80: Color.lerp(primaryAlpha80, other.primaryAlpha80, t)!,
      primaryAlpha80Hover:
          Color.lerp(primaryAlpha80Hover, other.primaryAlpha80Hover, t)!,
      white: Color.lerp(white, other.white, t)!,
      whiteAlpha: Color.lerp(whiteAlpha, other.whiteAlpha, t)!,
      whiteAlphaHover: Color.lerp(whiteAlphaHover, other.whiteAlphaHover, t)!,
      black: Color.lerp(black, other.black, t)!,
      themeLight: Color.lerp(themeLight, other.themeLight, t)!,
      themeLightHover: Color.lerp(themeLightHover, other.themeLightHover, t)!,
      themeThick: Color.lerp(themeThick, other.themeThick, t)!,
      themeThickHover: Color.lerp(themeThickHover, other.themeThickHover, t)!,
      themeSelect: Color.lerp(themeSelect, other.themeSelect, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      infoLightHover: Color.lerp(infoLightHover, other.infoLightHover, t)!,
      infoThick: Color.lerp(infoThick, other.infoThick, t)!,
      infoThickHover: Color.lerp(infoThickHover, other.infoThickHover, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      successLightHover:
          Color.lerp(successLightHover, other.successLightHover, t)!,
      successThick: Color.lerp(successThick, other.successThick, t)!,
      successThickHover:
          Color.lerp(successThickHover, other.successThickHover, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      warningLightHover:
          Color.lerp(warningLightHover, other.warningLightHover, t)!,
      warningThick: Color.lerp(warningThick, other.warningThick, t)!,
      warningThickHover:
          Color.lerp(warningThickHover, other.warningThickHover, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      errorLightHover: Color.lerp(errorLightHover, other.errorLightHover, t)!,
      errorThick: Color.lerp(errorThick, other.errorThick, t)!,
      errorThickHover: Color.lerp(errorThickHover, other.errorThickHover, t)!,
      errorSelect: Color.lerp(errorSelect, other.errorSelect, t)!,
      purpleLight: Color.lerp(purpleLight, other.purpleLight, t)!,
      purpleLightHover:
          Color.lerp(purpleLightHover, other.purpleLightHover, t)!,
      purpleThick: Color.lerp(purpleThick, other.purpleThick, t)!,
      purpleThickHover:
          Color.lerp(purpleThickHover, other.purpleThickHover, t)!,
    );
  }
}
