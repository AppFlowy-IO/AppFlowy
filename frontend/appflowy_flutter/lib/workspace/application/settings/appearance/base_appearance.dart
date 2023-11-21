import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class BaseAppearance {
  final white = const Color(0xFFFFFFFF);

  final Set<MaterialState> scrollbarInteractiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.dragged,
  };

  TextStyle getFontStyle({
    required String fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? fontColor,
    double? letterSpacing,
    double? lineHeight,
  }) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize ?? FontSizes.s12,
        color: fontColor,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: (fontSize ?? FontSizes.s12) * (letterSpacing ?? 0.005),
        height: lineHeight,
      );
    } catch (e) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? FontSizes.s12,
        color: fontColor,
        fontWeight: fontWeight ?? FontWeight.w500,
        fontFamilyFallback: const ['Poppins'],
        letterSpacing: (fontSize ?? FontSizes.s12) * (letterSpacing ?? 0.005),
        height: lineHeight,
      );
    }
  }

  TextTheme getTextTheme({
    required String fontFamily,
    required Color fontColor,
  }) {
    return TextTheme(
      displayLarge: getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s32,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
        lineHeight: 42.0,
      ), // h2
      displayMedium: getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s24,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
        lineHeight: 34.0,
      ), // h3
      displaySmall: getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s20,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
        lineHeight: 28.0,
      ), // h4
      titleLarge: getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s18,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
      ), // title
      titleMedium: getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s16,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
      ), // heading
      titleSmall: getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s14,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
      ), // subheading
      bodyMedium: getFontStyle(
        fontFamily: fontFamily,
        fontColor: fontColor,
      ), // body-regular
      bodySmall: getFontStyle(
        fontFamily: fontFamily,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
      ), // body-thin
    );
  }

  ThemeData getThemeData(
    AppTheme appTheme,
    Brightness brightness,
    String fontFamily,
    String codeFontFamily,
  );
}
