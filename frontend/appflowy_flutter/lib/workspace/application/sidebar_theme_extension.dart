import 'package:flutter/material.dart';

class AFSideBarThemeExtension extends ThemeExtension<AFSideBarThemeExtension> {
  const AFSideBarThemeExtension({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.titleTextStyle,
    required this.subTitleTextStyle,
    required this.subTitleTextColor,
    required this.hoverBgColor,
    required this.hoverTextColor,
    required this.tooltipBgColor,
    required this.tooltipTextStyle,
  });

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final TextStyle? titleTextStyle;
  final TextStyle? subTitleTextStyle;
  final Color? subTitleTextColor;
  final Color? hoverBgColor;
  final Color? hoverTextColor;
  final Color? tooltipBgColor;
  final TextStyle? tooltipTextStyle;

  @override
  ThemeExtension<AFSideBarThemeExtension> copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? iconColor,
    TextStyle? titleTextStyle,
    TextStyle? subTitleTextStyle,
    Color? subTitleTextColor,
    Color? hoverBgColor,
    Color? hoverTextColor,
    Color? tooltipBgColor,
    TextStyle? tooltipTextStyle,
  }) {
    return AFSideBarThemeExtension(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      iconColor: iconColor ?? this.iconColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      subTitleTextStyle: subTitleTextStyle ?? this.subTitleTextStyle,
      subTitleTextColor: subTitleTextColor ?? this.subTitleTextColor,
      hoverBgColor: hoverBgColor ?? this.hoverBgColor,
      hoverTextColor: hoverTextColor ?? this.hoverTextColor,
      tooltipBgColor: tooltipBgColor ?? this.tooltipBgColor,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
    );
  }

  @override
  ThemeExtension<AFSideBarThemeExtension> lerp(
      ThemeExtension<AFSideBarThemeExtension>? other, double t) {
    if (other is! AFSideBarThemeExtension) {
      return this;
    }
    return AFSideBarThemeExtension(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
      subTitleTextStyle:
          TextStyle.lerp(subTitleTextStyle, other.subTitleTextStyle, t),
      subTitleTextColor:
          Color.lerp(subTitleTextColor, other.subTitleTextColor, t),
      hoverBgColor: Color.lerp(hoverBgColor, other.hoverBgColor, t),
      hoverTextColor: Color.lerp(hoverTextColor, other.hoverTextColor, t),
      tooltipBgColor: Color.lerp(tooltipBgColor, other.tooltipBgColor, t),
      tooltipTextStyle:
          TextStyle.lerp(tooltipTextStyle, other.tooltipTextStyle, t),
    );
  }

  static const light = AFSideBarThemeExtension(
    backgroundColor: Color(0xFFF7F8FC),
    borderColor: Color(0xFFF2F2F2),
    iconColor: Color(0xFF333333),
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w500,
      color: Color(0xFF333333),
      fontSize: 12,
    ),
    subTitleTextStyle: TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 12,
    ),
    subTitleTextColor: Color(0xFF333333),
    hoverBgColor: Color(0xFFE0F8FF),
    hoverTextColor: Color(0xFF333333),
    tooltipBgColor: Color(0xFFE0F8FF),
    tooltipTextStyle: TextStyle(
      fontWeight: FontWeight.w500,
      color: Color(0xFF333333),
      fontSize: 12,
    ),
  );

  static const dark = AFSideBarThemeExtension(
    backgroundColor: Color(0xFF232B38),
    borderColor: Color(0xFFF2F2F2),
    iconColor: Color(0xFFBBC3CD),
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontSize: 12,
    ),
    subTitleTextStyle: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 12,
    ),
    subTitleTextColor: Color(0xFFBBC3CD),
    hoverBgColor: Color(0xFF363D49),
    hoverTextColor: Color(0xFF131720),
    tooltipBgColor: Color(0xFF00BCF0),
    tooltipTextStyle: TextStyle(
      fontWeight: FontWeight.w500,
      color: Color(0xFF131720),
      fontSize: 12,
    ),
  );
}
