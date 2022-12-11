import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flutter/material.dart';

import 'theme_extension.dart';

const List<String> builtInThemes = [
  'light',
];

const _white = Color(0xFFFFFFFF);

class AppTheme {
  // metadata member
  final FlowyColorScheme? lightTheme;
  final FlowyColorScheme? darkTheme;
  // static final Map<String, dynamic> _cachedJsonData = {};

  const AppTheme({
    this.lightTheme,
    this.darkTheme,
  });

  factory AppTheme.fromName({required String themeName}) {
    // if (builtInThemes.contains(themeName)) {
    //   return AppTheme(
    //     lightTheme: FlowyColorScheme.builtIn(themeName, Brightness.light),
    //     darkTheme: FlowyColorScheme.builtIn(themeName, Brightness.dark),
    //   );
    // } else {
    //   // load from Json
    //   return AppTheme(
    //     lightTheme: FlowyColorScheme.fromJson(_jsonData, Brightness.light),
    //     darkTheme: FlowyColorScheme.fromJson(_jsonData, Brightness.dark),
    //   );
    // }
    return AppTheme(
      lightTheme: FlowyColorScheme.builtIn(themeName, Brightness.light),
      darkTheme: FlowyColorScheme.builtIn(themeName, Brightness.dark),
    );
  }
}

ThemeData getThemeData(AppTheme appTheme, Brightness brightness,
    TextStyles textTheme, Locale locale) {
  // Poppins and SF Mono are not well supported in some languages, so use the
  // built-in font for the following languages.
  final useBuiltInFontLanguages = [
    const Locale('zh', 'CN'),
    const Locale('zh', 'TW'),
  ];
  if (useBuiltInFontLanguages.contains(locale)) {
    textTheme = TextStyles(font: '', monospaceFont: '');
  }

  final theme = brightness == Brightness.light
      ? appTheme.lightTheme!
      : appTheme.darkTheme!;

  return ThemeData(
    brightness: brightness,
    textTheme: textTheme.getTextTheme(fontColor: theme.shader1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: theme.main2,
      selectionHandleColor: theme.main2,
    ),
    primaryIconTheme: IconThemeData(color: theme.hover),
    iconTheme: IconThemeData(color: theme.shader1),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(Colors.transparent),
    ),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    canvasColor: theme.shader6,
    dividerColor: theme.shader6,
    hintColor: theme.shader3,
    disabledColor: theme.shader4,
    highlightColor: theme.main1,
    indicatorColor: theme.main1,
    toggleableActiveColor: theme.main1,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: theme.main1,
      onPrimary: _white,
      primaryContainer: theme.main2,
      onPrimaryContainer: _white,
      secondary: theme.hover,
      onSecondary: theme.shader1,
      secondaryContainer: theme.selector,
      onSecondaryContainer: theme.shader1,
      background: theme.surface,
      onBackground: theme.shader1,
      surface: theme.surface,
      onSurface: theme.shader1,
      onError: theme.shader7,
      error: theme.red,
      outline: theme.shader4,
      surfaceVariant: theme.bg1,
      shadow: theme.shadow,
    ),
    extensions: [
      AFThemeExtension(
        warning: theme.yellow,
        success: theme.green,
        tint1: theme.tint1,
        tint2: theme.tint2,
        tint3: theme.tint3,
        tint4: theme.tint4,
        tint5: theme.tint5,
        tint6: theme.tint6,
        tint7: theme.tint7,
        tint8: theme.tint8,
        tint9: theme.tint9,
        greyHover: theme.bg2,
        greySelect: theme.bg3,
        lightGreyHover: theme.shader6,
        toggleOffFill: theme.shader5,
        code: textTheme.getMonospaceFontSyle(fontColor: theme.shader1),
        callout: textTheme.getFontStyle(
          fontSize: FontSizes.s11,
          fontColor: theme.shader3,
        ),
        caption: textTheme.getFontStyle(
          fontSize: FontSizes.s11,
          fontWeight: FontWeight.w400,
          fontColor: theme.shader3,
        ),
      )
    ],
  );
}
