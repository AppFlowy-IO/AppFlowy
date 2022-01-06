import 'package:flowy_infra/color.dart';
import 'package:flutter/material.dart';

enum ThemeType {
  light,
  dark,
}

//Color Pallettes
const _black = Color(0xff000000);
const _grey = Color(0xff808080);
const _white = Color(0xFFFFFFFF);
const _gray_shade200 = Color(0xFFEEEEEE);
const _main2 = Color(0xff00b7ea);

class AppTheme {
  static ThemeType defaultTheme = ThemeType.light;

  bool isDark;
  late Color surface; //
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

  late Color main1;
  late Color main2;

  /// Default constructor
  AppTheme({this.isDark = false});

  /// fromType factory constructor
  factory AppTheme.fromType(ThemeType t) {
    switch (t) {
      case ThemeType.light:
        return AppTheme(isDark: false)
          ..surface = _gray_shade200
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
          ..shader7 = _white
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
          ..tint9 = const Color(0xffdefff1)
          ..main1 = const Color(0xff00bcf0)
          ..main2 = const Color(0xff00b7ea)
          ..textColor = _black;

      case ThemeType.dark:
        return AppTheme(isDark: true)
          ..surface = const Color(0xff292929)
          ..hover = const Color(0xff1f1f1f)
          ..selector = _black
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
          ..bg3 = _grey
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
          ..textColor = _white;
    }
  }

  ThemeData get themeData {
    var t = ThemeData(
      textTheme: TextTheme(bodyText1: TextStyle(), bodyText2: TextStyle().apply(color: textColor)),
      textSelectionTheme: TextSelectionThemeData(cursorColor: main2, selectionHandleColor: main2),
      primaryIconTheme: IconThemeData(color: hover),
      iconTheme: IconThemeData(color: shader1),
      canvasColor: shader7,
      hoverColor: main2,
      colorScheme: ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: main1,
          primaryVariant: main2,
          secondary: main2,
          secondaryVariant: main2,
          background: bg1,
          surface: surface,
          onBackground: bg1,
          onSurface: surface,
          onError: red,
          onPrimary: bg1,
          onSecondary: bg1,
          error: red),
    );

    return t.copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        highlightColor: main1,
        indicatorColor: main1,
        toggleableActiveColor: main1);
  }

  Color shift(Color c, double d) => ColorUtils.shiftHsl(c, d * (isDark ? -1 : 1));
}
