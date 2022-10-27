import 'package:flutter/material.dart';

Brightness themeTypeFromString(String name) {
  Brightness themeType = Brightness.light;
  if (name == "dark") {
    themeType = Brightness.dark;
  }
  return themeType;
}

String themeTypeToString(Brightness brightness) {
  switch (brightness) {
    case Brightness.light:
      return "light";
    case Brightness.dark:
      return "dark";
  }
}

// Color Pallettes
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

  late Color shadowColor;

  /// Default constructor
  AppTheme({this.brightness = Brightness.light});

  factory AppTheme.fromName({required String name}) {
    return AppTheme.fromType(themeTypeFromString(name));
  }

  /// fromType factory constructor
  factory AppTheme.fromType(Brightness themeType) {
    switch (themeType) {
      case Brightness.light:
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
          ..shadowColor = _black
          ..disableIconColor = const Color(0xffbdbdbd);

      case Brightness.dark:
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
          ..shadowColor = _white
          ..disableIconColor = const Color(0xff333333);
    }
  }

  ThemeData get themeData {
    var t = ThemeData(
      textTheme: TextTheme(bodyText2: TextStyle(color: textColor)),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: main2, selectionHandleColor: main2),
      primaryIconTheme: IconThemeData(color: hover),
      iconTheme: IconThemeData(color: shader1),
      canvasColor: shader6,
      //Don't use this property because of the redo/undo button in the toolbar use the hoverColor.
      // hoverColor: main2,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: main1,
        secondary: main2,
        background: surface,
        surface: surface,
        onBackground: surface,
        onSurface: surface,
        onError: red,
        onPrimary: bg1,
        onSecondary: bg1,
        error: red,
      ),
    );

    return t.copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        highlightColor: main1,
        indicatorColor: main1,
        toggleableActiveColor: main1);
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
