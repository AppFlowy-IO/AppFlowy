import 'package:flutter/material.dart';

@immutable
class AFThemeExtension extends ThemeExtension<AFThemeExtension> {
  final Color? warning;
  final Color? success;

  final Color tint1;
  final Color tint2;
  final Color tint3;
  final Color tint4;
  final Color tint5;
  final Color tint6;
  final Color tint7;
  final Color tint8;
  final Color tint9;

  final Color greyHover;
  final Color greySelect;
  final Color lightGreyHover;
  final Color toggleOffFill;

  final TextStyle code;
  final TextStyle callout;
  final TextStyle caption;

  const AFThemeExtension({
    required this.warning,
    required this.success,
    required this.tint1,
    required this.tint2,
    required this.tint3,
    required this.tint4,
    required this.tint5,
    required this.tint6,
    required this.tint7,
    required this.tint8,
    required this.tint9,
    required this.greyHover,
    required this.greySelect,
    required this.lightGreyHover,
    required this.toggleOffFill,
    required this.code,
    required this.callout,
    required this.caption,
  });

  static AFThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AFThemeExtension>()!;
  }

  @override
  AFThemeExtension copyWith({
    Color? warning,
    Color? success,
    Color? tint1,
    Color? tint2,
    Color? tint3,
    Color? tint4,
    Color? tint5,
    Color? tint6,
    Color? tint7,
    Color? tint8,
    Color? tint9,
    Color? greyHover,
    Color? greySelect,
    Color? lightGreyHover,
    Color? toggleOffFill,
    TextStyle? code,
    TextStyle? callout,
    TextStyle? caption,
  }) {
    return AFThemeExtension(
      warning: warning ?? this.warning,
      success: success ?? this.success,
      tint1: tint1 ?? this.tint1,
      tint2: tint2 ?? this.tint2,
      tint3: tint3 ?? this.tint3,
      tint4: tint4 ?? this.tint4,
      tint5: tint5 ?? this.tint5,
      tint6: tint6 ?? this.tint6,
      tint7: tint7 ?? this.tint7,
      tint8: tint8 ?? this.tint8,
      tint9: tint9 ?? this.tint9,
      greyHover: greyHover ?? this.greyHover,
      greySelect: greySelect ?? this.greySelect,
      lightGreyHover: lightGreyHover ?? this.lightGreyHover,
      toggleOffFill: toggleOffFill ?? this.toggleOffFill,
      code: code ?? this.code,
      callout: callout ?? this.callout,
      caption: caption ?? this.caption,
    );
  }

  @override
  ThemeExtension<AFThemeExtension> lerp(
      ThemeExtension<AFThemeExtension>? other, double t) {
    if (other is! AFThemeExtension) {
      return this;
    }
    return AFThemeExtension(
      warning: Color.lerp(warning, other.warning, t),
      success: Color.lerp(success, other.success, t),
      tint1: Color.lerp(tint1, other.tint1, t)!,
      tint2: Color.lerp(tint2, other.tint2, t)!,
      tint3: Color.lerp(tint3, other.tint3, t)!,
      tint4: Color.lerp(tint4, other.tint4, t)!,
      tint5: Color.lerp(tint5, other.tint5, t)!,
      tint6: Color.lerp(tint6, other.tint6, t)!,
      tint7: Color.lerp(tint7, other.tint7, t)!,
      tint8: Color.lerp(tint8, other.tint8, t)!,
      tint9: Color.lerp(tint9, other.tint9, t)!,
      greyHover: Color.lerp(greyHover, other.greyHover, t)!,
      greySelect: Color.lerp(greySelect, other.greySelect, t)!,
      lightGreyHover: Color.lerp(lightGreyHover, other.lightGreyHover, t)!,
      toggleOffFill: Color.lerp(toggleOffFill, other.toggleOffFill, t)!,
      code: other.code,
      callout: other.callout,
      caption: other.caption,
    );
  }
}
