import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';

class Fonts {
  static String general = "Poppins";

  static String monospace = "SF Mono";

  static String emoji = "Noto Color Emoji";
}

class TextStyles {
  static TextStyle general({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: Fonts.general,
        fontSize: fontSize ?? FontSizes.s12,
        color: color,
        fontWeight: fontWeight,
        fontFamilyFallback: [Fonts.emoji],
        letterSpacing: (fontSize ?? FontSizes.s12) * 0.005,
      );

  static TextStyle monospace({
    String? fontFamily,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: fontFamily ?? Fonts.monospace,
        fontSize: fontSize ?? FontSizes.s12,
        fontWeight: fontWeight,
        fontFamilyFallback: [Fonts.emoji],
      );

  static TextStyle get title => general(
        fontSize: FontSizes.s18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get subheading => general(
        fontSize: FontSizes.s16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get subtitle => general(
        fontSize: FontSizes.s16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body1 => general(
        fontSize: FontSizes.s12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get body2 => general(
        fontSize: FontSizes.s12,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get callout => general(
        fontSize: FontSizes.s11,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get caption => general(
        fontSize: FontSizes.s11,
        fontWeight: FontWeight.w400,
      );
}
