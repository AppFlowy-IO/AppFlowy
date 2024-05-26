import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

// the default font family is empty, so we can use the default font family of the platform
// the system will choose the default font family of the platform
// iOS: San Francisco
// Android: Roboto
// Desktop: Based on the OS
const defaultFontFamily = '';

// the Poppins font is embedded in the app, so we can use it without GoogleFonts
// TODO(Lucas): after releasing version 0.5.6, remove it.
const fallbackFontFamily = 'Poppins';
const builtInCodeFontFamily = 'RobotoMono';

abstract class BaseAppearance {
  final white = const Color(0xFFFFFFFF);

  final Set<WidgetState> scrollbarInteractiveStates = <WidgetState>{
    WidgetState.pressed,
    WidgetState.hovered,
    WidgetState.dragged,
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
      fontFamily: fontFamily.isEmpty ? null : fontFamily,
      fontSize: fontSize,
      color: fontColor,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    if (fontFamily == defaultFontFamily || fontFamily == fallbackFontFamily) {
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
