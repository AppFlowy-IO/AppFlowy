import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';

class TextStyles {
  final String font;
  final Color color;

  TextStyles({
    required this.font,
    required this.color,
  });

  TextStyle getFontStyle({
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? fontColor,
    double? letterSpacing,
    double? lineHeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily ?? font,
        fontSize: fontSize ?? FontSizes.s12,
        color: fontColor ?? color,
        fontWeight: fontWeight ?? FontWeight.w500,
        fontFamilyFallback: const ["Noto Color Emoji"],
        letterSpacing: (fontSize ?? FontSizes.s12) * (letterSpacing ?? 0.005),
        height: lineHeight,
      );

  TextTheme generateTextTheme() {
    return TextTheme(
      displayLarge: getFontStyle(
        fontSize: FontSizes.s32,
        fontWeight: FontWeight.w600,
        lineHeight: 42.0,
      ), // h2
      displayMedium: getFontStyle(
        fontSize: FontSizes.s24,
        fontWeight: FontWeight.w600,
        lineHeight: 34.0,
      ), // h3
      displaySmall: getFontStyle(
        fontSize: FontSizes.s20,
        fontWeight: FontWeight.w600,
        lineHeight: 28.0,
      ), // h4
      titleLarge: getFontStyle(
        fontSize: FontSizes.s18,
        fontWeight: FontWeight.w600,
      ), // title
      titleMedium: getFontStyle(
        fontSize: FontSizes.s16,
        fontWeight: FontWeight.w600,
      ), // heading
      titleSmall: getFontStyle(
        fontSize: FontSizes.s14,
        fontWeight: FontWeight.w600,
      ), // subheading
      bodyMedium: getFontStyle(), // body-regular
      bodySmall: getFontStyle(fontWeight: FontWeight.w400), // body-thin
    );
  }
}
