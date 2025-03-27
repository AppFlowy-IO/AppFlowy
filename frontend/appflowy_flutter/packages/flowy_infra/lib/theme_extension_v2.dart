// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

@immutable
class AFThemeExtensionV2 extends ThemeExtension<AFThemeExtensionV2> {
  static AFThemeExtensionV2 of(BuildContext context) =>
      Theme.of(context).extension<AFThemeExtensionV2>()!;

  static AFThemeExtensionV2? maybeOf(BuildContext context) =>
      Theme.of(context).extension<AFThemeExtensionV2>();

  const AFThemeExtensionV2({
    required this.icon_primary,
    required this.icon_tertiary,
    required this.border_grey_quaternary,
    required this.fill_theme_select,
    required this.fill_grey_thick_alpha_1,
    required this.shadow_medium,
  });

  final Color icon_primary;
  final Color icon_tertiary;
  final Color border_grey_quaternary;
  final Color fill_theme_select;
  final Color fill_grey_thick_alpha_1;
  final Color shadow_medium;

  @override
  AFThemeExtensionV2 copyWith({
    Color? icon_primary,
    Color? icon_tertiary,
    Color? border_grey_quaternary,
    Color? fill_theme_select,
    Color? fill_grey_thick_alpha_1,
    Color? shadow_medium,
  }) =>
      AFThemeExtensionV2(
        icon_primary: icon_primary ?? this.icon_primary,
        icon_tertiary: icon_tertiary ?? this.icon_tertiary,
        border_grey_quaternary:
            border_grey_quaternary ?? this.border_grey_quaternary,
        fill_theme_select: fill_theme_select ?? this.fill_theme_select,
        fill_grey_thick_alpha_1:fill_grey_thick_alpha_1 ?? this.fill_grey_thick_alpha_1,
        shadow_medium:shadow_medium ?? this.shadow_medium,
      );

  @override
  ThemeExtension<AFThemeExtensionV2> lerp(
      ThemeExtension<AFThemeExtensionV2>? other, double t) {
    if (other is! AFThemeExtensionV2) {
      return this;
    }
    return AFThemeExtensionV2(
      icon_primary:
          Color.lerp(icon_primary, other.icon_primary, t) ?? icon_primary,
      icon_tertiary:
          Color.lerp(icon_tertiary, other.icon_tertiary, t) ?? icon_tertiary,
      border_grey_quaternary:
          Color.lerp(border_grey_quaternary, other.border_grey_quaternary, t) ??
              border_grey_quaternary,
      fill_theme_select:
          Color.lerp(fill_theme_select, other.fill_theme_select, t) ??
              fill_theme_select,
      fill_grey_thick_alpha_1: Color.lerp(
              fill_grey_thick_alpha_1, other.fill_grey_thick_alpha_1, t) ??
          fill_grey_thick_alpha_1,
      shadow_medium: Color.lerp(
              shadow_medium, other.shadow_medium, t) ??
          shadow_medium,
    );
  }
}

const AFThemeExtensionV2 darkAFThemeV2 = AFThemeExtensionV2(
  icon_primary: Color(0xFF1F2329),
  icon_tertiary: Color(0xFF99A1A8),
  border_grey_quaternary: Color(0xFFE8ECF3),
  fill_theme_select: Color(0x00BCF01F),
  fill_grey_thick_alpha_1: Color(0x1F23290F),
  shadow_medium: Color(0x1F22251F),
);

const AFThemeExtensionV2 lightAFThemeV2 = AFThemeExtensionV2(
  icon_primary: Color(0xFF1F2329),
  icon_tertiary: Color(0xFF99A1A8),
  border_grey_quaternary: Color(0xFFE8ECF3),
  fill_theme_select: Color(0x00BCF01F),
  fill_grey_thick_alpha_1: Color(0x1F23290F),
  shadow_medium: Color(0x1F22251F),
);
