import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infra/color.dart';

enum ThemeType {
  light,
  dark,
}

class AppTheme {
  static ThemeType defaultTheme = ThemeType.light;

  bool isDark;
  late Color bg1; //
  late Color surface; //
  late Color bg2;
  late Color accent1;
  late Color accent1Dark;
  late Color accent1Darker;
  late Color accent2;
  late Color accent3;
  late Color grey;
  late Color greyStrong;
  late Color greyWeak;
  late Color error;
  late Color focus;

  late Color txt;
  late Color accentTxt;

  /// Default constructor
  AppTheme({this.isDark = true}) {
    txt = isDark ? Colors.white : Colors.black;
    accentTxt = isDark ? Colors.black : Colors.white;
  }

  /// fromType factory constructor
  factory AppTheme.fromType(ThemeType t) {
    switch (t) {
      case ThemeType.light:
        return AppTheme(isDark: false)
          ..bg1 = const Color(0xfff1f7f0)
          ..bg2 = const Color(0xffc1dcbc)
          ..surface = Colors.white
          ..accent1 = const Color(0xff00a086)
          ..accent1Dark = const Color(0xff00856f)
          ..accent1Darker = const Color(0xff006b5a)
          ..accent2 = const Color(0xfff09433)
          ..accent3 = const Color(0xff5bc91a)
          ..greyWeak = const Color(0xff909f9c)
          ..grey = const Color(0xff515d5a)
          ..greyStrong = const Color(0xff151918)
          ..error = Colors.red.shade900
          ..focus = const Color(0xFF0ee2b1);

      case ThemeType.dark:
        return AppTheme(isDark: true)
          ..bg1 = const Color(0xff121212)
          ..bg2 = const Color(0xff2c2c2c)
          ..surface = const Color(0xff252525)
          ..accent1 = const Color(0xff00a086)
          ..accent1Dark = const Color(0xff00caa5)
          ..accent1Darker = const Color(0xff00caa5)
          ..accent2 = const Color(0xfff19e46)
          ..accent3 = const Color(0xff5BC91A)
          ..greyWeak = const Color(0xffa8b3b0)
          ..grey = const Color(0xffced4d3)
          ..greyStrong = const Color(0xffffffff)
          ..error = const Color(0xffe55642)
          ..focus = const Color(0xff0ee2b1);
    }
  }

  ThemeData get themeData {
    var t = ThemeData.from(
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme,
      colorScheme: ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: accent1,
          primaryVariant: accent1Darker,
          secondary: accent2,
          secondaryVariant: ColorUtils.shiftHsl(accent2, -.2),
          background: bg1,
          surface: surface,
          onBackground: txt,
          onSurface: txt,
          onError: txt,
          onPrimary: accentTxt,
          onSecondary: accentTxt,
          error: error),
    );
    return t.copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        highlightColor: accent1,
        toggleableActiveColor: accent1);
  }

  Color shift(Color c, double d) =>
      ColorUtils.shiftHsl(c, d * (isDark ? -1 : 1));
}
