import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? warning;
  final Color? success;

  static Color tint1 = const Color(0xffe8e0ff);
  static Color tint2 = const Color(0xffffe7fd);
  static Color tint3 = const Color(0xffffe7ee);
  static Color tint4 = const Color(0xffffefe3);
  static Color tint5 = const Color(0xfffff2cd);
  static Color tint6 = const Color(0xfff5ffdc);
  static Color tint7 = const Color(0xffddffd6);
  static Color tint8 = const Color(0xffdefff1);
  static Color tint9 = const Color(0xffe1fbff);

  final Color? greyHover;
  final Color? greySelect;
  final Color? lightGreyHover;
  final Color? toggleOffFill;

  const CustomColors({
    required this.warning,
    required this.success,
    this.greyHover,
    this.greySelect,
    this.lightGreyHover,
    this.toggleOffFill,
  });

  @override
  CustomColors copyWith({
    Color? warning,
    Color? success,
    Color? greyHover,
    Color? greySelect,
    Color? lightGreyHover,
    Color? toggleOffFill,
  }) {
    return CustomColors(
      warning: warning ?? this.warning,
      success: success ?? this.success,
      greyHover: greyHover ?? this.greyHover,
      greySelect: greySelect ?? this.greySelect,
      lightGreyHover: lightGreyHover ?? this.lightGreyHover,
      toggleOffFill: toggleOffFill ?? this.toggleOffFill,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(
      ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      warning: Color.lerp(warning, other.warning, t),
      success: Color.lerp(success, other.success, t),
      greyHover: Color.lerp(greyHover, other.greyHover, t),
      greySelect: Color.lerp(greySelect, other.greySelect, t),
      lightGreyHover: Color.lerp(lightGreyHover, other.lightGreyHover, t),
      toggleOffFill: Color.lerp(toggleOffFill, other.toggleOffFill, t),
    );
  }
}
