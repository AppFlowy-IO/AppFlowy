import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';

String builtInFontFamily() {
  if (PlatformExtension.isDesktopOrWeb) {
    return 'Poppins';
  }

  if (Platform.isIOS) {
    return 'San Francisco';
  }

  if (Platform.isAndroid) {
    return 'Roboto';
  }

  return 'Roboto';
}

// 'Poppins';
const builtInCodeFontFamily = 'RobotoMono';

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
    fontSize = fontSize ?? FontSizes.s12;
    fontWeight = fontWeight ??
        (PlatformExtension.isDesktopOrWeb ? FontWeight.w500 : FontWeight.w400);
    letterSpacing = fontSize * (letterSpacing ?? 0.005);

    final textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: fontColor,
      fontWeight: fontWeight,
      fontFamilyFallback: [builtInFontFamily()],
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    // we embed Poppins font in the app, so we can use it without GoogleFonts
    if (fontFamily == builtInFontFamily()) {
      return textStyle;
    }

    try {
      return getGoogleFontSafely(
        fontFamily,
        fontSize: fontSize,
        fontColor: fontColor,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        lineHeight: lineHeight,
      );
    } catch (e) {
      return textStyle;
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
