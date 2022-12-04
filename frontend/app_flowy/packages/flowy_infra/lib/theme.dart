import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flutter/material.dart';

import 'color_extension.dart';

enum ThemeType { light, dark, anne }

Color getCardColor(ThemeType ty) {
  switch (ty) {
    case ThemeType.light:
      return const Color.fromARGB(255, 214, 214, 218);
    case ThemeType.dark:
      return const Color(0xff000000);
    case ThemeType.anne:
      return const Color(0xFFFFCE31);
    default:
      return const Color.fromARGB(255, 214, 214, 218);
  }
}

ThemeType themeTypeFromString(String name) {
  ThemeType themeType = ThemeType.light;
  if (name == "dark") {
    themeType = ThemeType.dark;
  } else if (name == "anne") {
    themeType = ThemeType.anne;
  }
  return themeType;
}

String themeTypeToString(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.light:
      return "light";
    case ThemeType.dark:
      return "dark";
    case ThemeType.anne:
      return "anne";
  }
}

// Color Palettes
const _black = Color(0xff000000);
const _white = Color(0xFFFFFFFF);

class AppTheme {
  Brightness brightness;

  late Color surface;
  late Color hover;
  late Color selector;
  late Color red;
  late Color yellow;
  late Color green;

  late Color shader1;
  late Color shader2;
  late Color shader3;
  late Color shader4;
  late Color shader5;
  late Color shader6;
  late Color shader7;

  late Color bg1;
  late Color bg2;
  late Color bg3;
  late Color bg4;

  late Color tint1;
  late Color tint2;
  late Color tint3;
  late Color tint4;
  late Color tint5;
  late Color tint6;
  late Color tint7;
  late Color tint8;
  late Color tint9;

  late Color textColor;
  late Color iconColor;
  late Color disableIconColor;

  late Color main1;
  late Color main2;

  late Color shadow;

  late String font;
  late String monospaceFont;

  /// Default constructor
  AppTheme({this.brightness = Brightness.light});

  factory AppTheme.fromName({
    required String themeName,
    required String font,
    required String monospaceFont,
  }) {
    switch (themeTypeFromString(themeName)) {
      case ThemeType.light:
        return AppTheme(brightness: Brightness.light)
          ..surface = Colors.white
          ..hover = const Color(0xFFe0f8ff)
          ..selector = const Color(0xfff2fcff)
          ..red = const Color(0xfffb006d)
          ..yellow = const Color(0xffffd667)
          ..green = const Color(0xff66cf80)
          ..shader1 = const Color(0xff333333)
          ..shader2 = const Color(0xff4f4f4f)
          ..shader3 = const Color(0xff828282)
          ..shader4 = const Color(0xffbdbdbd)
          ..shader5 = const Color(0xffe0e0e0)
          ..shader6 = const Color(0xfff2f2f2)
          ..shader7 = const Color(0xffffffff)
          ..bg1 = const Color(0xfff7f8fc)
          ..bg2 = const Color(0xffedeef2)
          ..bg3 = const Color(0xffe2e4eb)
          ..bg4 = const Color(0xff2c144b)
          ..tint1 = const Color(0xffe8e0ff)
          ..tint2 = const Color(0xffffe7fd)
          ..tint3 = const Color(0xffffe7ee)
          ..tint4 = const Color(0xffffefe3)
          ..tint5 = const Color(0xfffff2cd)
          ..tint6 = const Color(0xfff5ffdc)
          ..tint7 = const Color(0xffddffd6)
          ..tint8 = const Color(0xffdefff1)
          ..tint9 = const Color(0xffe1fbff)
          ..main1 = const Color(0xff00bcf0)
          ..main2 = const Color(0xff00b7ea)
          ..textColor = _black
          ..iconColor = _black
          ..shadow = _black
          ..disableIconColor = const Color(0xffbdbdbd)
          ..font = font
          ..monospaceFont = monospaceFont;

      case ThemeType.dark:
        return AppTheme(brightness: Brightness.dark)
          ..surface = const Color(0xff292929)
          ..hover = const Color(0xff1f1f1f)
          ..selector = const Color(0xff333333)
          ..red = const Color(0xfffb006d)
          ..yellow = const Color(0xffffd667)
          ..green = const Color(0xff66cf80)
          ..shader1 = _white
          ..shader2 = const Color(0xffffffff)
          ..shader3 = const Color(0xff828282)
          ..shader4 = const Color(0xffbdbdbd)
          ..shader5 = _white
          ..shader6 = _black
          ..shader7 = _black
          ..bg1 = _black
          ..bg2 = _black
          ..bg3 = const Color(0xff4f4f4f)
          ..bg4 = const Color(0xff2c144b)
          ..tint1 = const Color(0xffc3adff)
          ..tint2 = const Color(0xffffadf9)
          ..tint3 = const Color(0xffffadad)
          ..tint4 = const Color(0xffffcfad)
          ..tint5 = const Color(0xfffffead)
          ..tint6 = const Color(0xffe6ffa3)
          ..tint7 = const Color(0xffbcffad)
          ..tint8 = const Color(0xffadffe2)
          ..tint9 = const Color(0xffade4ff)
          ..main1 = const Color(0xff00bcf0)
          ..main2 = const Color(0xff009cc7)
          ..textColor = _white
          ..iconColor = _white
          ..shadow = _black
          ..disableIconColor = const Color(0xff333333)
          ..font = font
          ..monospaceFont = monospaceFont;
      case ThemeType.anne:
        return AppTheme(brightness: Brightness.light)
          ..surface = Colors.white
          ..hover = const Color(0xFFe0f8ff) //
          ..selector = const Color(0xfff2fcff)
          ..red = const Color(0xfffb006d)
          ..yellow = const Color(0xffffd667)
          ..green = const Color(0xff66cf80)
          ..shader1 = const Color(0xff333333)
          ..shader2 = const Color(0xff4f4f4f)
          ..shader3 = const Color(0xff828282)
          ..shader4 = const Color(0xffbdbdbd)
          ..shader5 = const Color(0xffe0e0e0)
          ..shader6 = const Color(0xfff2f2f2)
          ..shader7 = const Color(0xffffffff)
          ..bg1 = const Color(0xFFFFCE31)
          ..bg2 = const Color(0xffedeef2)
          ..bg3 = const Color(0xffe2e4eb)
          ..bg4 = const Color(0xff2c144b)
          ..tint1 = const Color(0xffe8e0ff)
          ..tint2 = const Color(0xffffe7fd)
          ..tint3 = const Color(0xffffe7ee)
          ..tint4 = const Color(0xffffefe3)
          ..tint5 = const Color(0xfffff2cd)
          ..tint6 = const Color(0xfff5ffdc)
          ..tint7 = const Color(0xffddffd6)
          ..tint8 = const Color(0xffdefff1)
          ..tint9 = const Color(0xffe1fbff)
          ..main1 = const Color(0xffe21f74)
          ..main2 = const Color.fromARGB(255, 224, 25, 111)
          ..textColor = _black
          ..iconColor = const Color(0xff9327ff)
          ..shadow = _black
          ..disableIconColor = const Color(0xff333333)
          ..font = font
          ..monospaceFont = monospaceFont;
    }
  }

  ThemeData getThemeData(Locale locale) {
    // Poppins and SF Mono are not well supported in some languages, so use the
    // built-in font for the following languages.
    final useBuiltInFontLanguages = [
      const Locale('zh', 'CN'),
      const Locale('zh', 'TW'),
    ];
    TextStyles textTheme;
    if (useBuiltInFontLanguages.contains(locale)) {
      textTheme = TextStyles(font: '', color: shader1);
    } else {
      textTheme = TextStyles(font: font, color: shader1);
    }
    return ThemeData(
      brightness: brightness,
      textTheme: textTheme.generateTextTheme(),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: main2,
        selectionHandleColor: main2,
      ),
      primaryIconTheme: IconThemeData(color: hover),
      iconTheme: IconThemeData(color: shader1),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(Colors.transparent),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      canvasColor: shader6,
      dividerColor: shader6,
      hintColor: shader3,
      disabledColor: shader4,
      highlightColor: main1,
      indicatorColor: main1,
      toggleableActiveColor: main1,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: main1,
        onPrimary: _white,
        primaryContainer: main2,
        onPrimaryContainer: _white,
        secondary: hover,
        onSecondary: shader1,
        secondaryContainer: selector,
        onSecondaryContainer: shader1,
        background: surface,
        onBackground: shader1,
        surface: surface,
        onSurface: shader1,
        onError: shader7,
        error: red,
        outline: shader4,
        surfaceVariant: bg1,
        shadow: shadow,
      ),
      extensions: [
        AFThemeExtension(
          warning: yellow,
          success: green,
          tint1: tint1,
          tint2: tint2,
          tint3: tint3,
          tint4: tint4,
          tint5: tint5,
          tint6: tint6,
          tint7: tint7,
          tint8: tint8,
          tint9: tint9,
          greyHover: bg2,
          greySelect: bg3,
          lightGreyHover: shader6,
          toggleOffFill: shader5,
          code: textTheme.getFontStyle(fontFamily: monospaceFont),
          callout: textTheme.getFontStyle(
            fontSize: FontSizes.s11,
            fontColor: shader3,
          ),
          caption: textTheme.getFontStyle(
            fontSize: FontSizes.s11,
            fontWeight: FontWeight.w400,
            fontColor: shader3,
          ),
        )
      ],
    );
  }

  Color shift(Color c, double d) =>
      ColorUtils.shiftHsl(c, d * (brightness == Brightness.dark ? -1 : 1));
}

class ColorUtils {
  static Color shiftHsl(Color c, [double amt = 0]) {
    var hslc = HSLColor.fromColor(c);
    return hslc.withLightness((hslc.lightness + amt).clamp(0.0, 1.0)).toColor();
  }

  static Color parseHex(String value) =>
      Color(int.parse(value.substring(1, 7), radix: 16) + 0xFF000000);

  static Color blend(Color dst, Color src, double opacity) {
    return Color.fromARGB(
      255,
      (dst.red.toDouble() * (1.0 - opacity) + src.red.toDouble() * opacity)
          .toInt(),
      (dst.green.toDouble() * (1.0 - opacity) + src.green.toDouble() * opacity)
          .toInt(),
      (dst.blue.toDouble() * (1.0 - opacity) + src.blue.toDouble() * opacity)
          .toInt(),
    );
  }
}
