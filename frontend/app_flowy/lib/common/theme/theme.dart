import 'package:flutter/material.dart';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flowy_infra/color.dart';

part 'theme.freezed.dart';

class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());

  void toggle() => emit(state.copyWith(isDark: state.isDark ? false : true));

  @override
  ThemeState fromJson(Map<String, dynamic> json) => ThemeState(isDark: json['isDark'] as bool);

  @override
  Map<String, dynamic> toJson(ThemeState state) => <String, bool>{'isDark': state.isDark};
}

@freezed
class ThemeState with _$ThemeState {
  const ThemeState._();
  const factory ThemeState({
    required bool isDark,
  }) = _ThemeState;

  factory ThemeState.initial() => const ThemeState(isDark: false);

  ThemeData get themeData => FlowyTheme(isDark).themeData;
}

extension ColorSchemeExtension on ColorScheme {
  Color get red => const Color(0xFFffadad);
  Color get orange => const Color(0xFFffcfad);
  Color get yellow => const Color(0xFFfffead);
  Color get lime => const Color(0xFFe6ffa3);
  Color get green => const Color(0xFFbcffad);
  Color get aqua => const Color(0xFFadffe2);
  Color get blue => const Color(0xFFade4ff);
  Color get purple => const Color(0xFFc3adff);
  Color get pink => const Color(0xFFffadf9);
}

// FIXME: Different colors for different themes (light/dark).
class FlowyTheme {
  const FlowyTheme([this.isDark = false]);

  final bool isDark;

  ThemeData get themeData => ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,

        primaryColor: const Color(0xFF00bcf0),

        // TODO: Custom color with tins and shades
        primarySwatch: Colors.blue,

        scaffoldBackgroundColor: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),
        backgroundColor: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),

        textTheme: const TextTheme(
          bodyText1: TextStyle(),
          bodyText2: TextStyle(),
        ).apply(
          bodyColor: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
          displayColor: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
        ),

        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF00bcf0),
          textTheme: ButtonTextTheme.normal,
        ),

        // textButtonTheme: TextButtonThemeData (
        //   style: ButtonStyle(
        //     backgroundColor: Color(0xFF00bcf0),
        //     foregroundColor: Colors.white,
        //     // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        //   ),
        //   )
        // ),

        colorScheme: ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,

          // Brand styles.
          primary: const Color(0xFF00bcf0),
          primaryVariant: const Color(0xFF009cc7),
          secondary: const Color(0xFFb061ff),
          secondaryVariant: const Color(0xFF9327ff),
          // onPrimary: const Color(0xFFf7f8fc),
          // onSecondary: const Color(0xFFf7f8fc),
          onPrimary: isDark ? Colors.white : Colors.black,
          onSecondary: isDark ? Colors.white : Colors.black,

          // Text styles.
          onBackground: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
          onSurface: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),

          // Backgrounds.
          background: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),
          surface: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),

          // Alerts.
          error: const Color(0xFFfb006d),
          onError: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
        ),

        // TODO: Add iconTheme
        // iconTheme: IconThemeData(color: Colors.purple.shade200, opacity: 0.8),
      );
}

// ------------------------------------------------

@Deprecated('')
enum ThemeType {
  light,
  dark,
}

//Color Pallettes
const _black = Color(0xff000000);
const _grey = Color(0xff808080);
const _white = Color(0xFFFFFFFF);

@Deprecated('Use `Theme.of(context).` instead')
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
  late Color iconColor;

  late Color main1;
  late Color main2;

  late Color shadowColor;

  /// Default constructor
  AppTheme({this.isDark = false});

  /// fromType factory constructor
  factory AppTheme.fromType(ThemeType t) {
    switch (t) {
      case ThemeType.light:
        return AppTheme(isDark: false)
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
          ..textColor = _black
          ..iconColor = _black
          ..shadowColor = _black;

      case ThemeType.dark:
        return AppTheme(isDark: true)
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
          ..textColor = _white
          ..iconColor = _white
          ..shadowColor = _white;
    }
  }

  ThemeData get themeData => ThemeData(
        // textTheme: TextTheme(bodyText2: TextStyle(color: textColor)),

        textSelectionTheme: TextSelectionThemeData(cursorColor: main2, selectionHandleColor: main2),
        primaryIconTheme: IconThemeData(color: hover),
        canvasColor: shader6,

        // FIXME: Don't use this property because of the redo/undo button in the toolbar use the hoverColor.
        hoverColor: isDark ? const Color(0xFF1f1f1f) : const Color(0xFFe0e0e0),

        primaryColor: const Color(0xFF00bcf0),

        // TODO: Custom color with tins and shades
        primarySwatch: Colors.blue,

        scaffoldBackgroundColor: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),
        backgroundColor: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),

        textTheme: const TextTheme(
          bodyText1: TextStyle(),
          bodyText2: TextStyle(),
        ).apply(
          bodyColor: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
          displayColor: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
        ),

        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF00bcf0),
          textTheme: ButtonTextTheme.normal,
        ),

        iconTheme: IconThemeData(color: isDark ? const Color(0xFFffffff) : const Color(0xFF333333), size: 16),

        colorScheme: ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,

          // Brand styles.
          primary: const Color(0xFF00bcf0),
          primaryVariant: const Color(0xFF009cc7),
          secondary: const Color(0xFFb061ff),
          secondaryVariant: const Color(0xFF9327ff),
          // onPrimary: const Color(0xFFf7f8fc),
          // onSecondary: const Color(0xFFf7f8fc),
          onPrimary: isDark ? Colors.white : Colors.black,
          onSecondary: isDark ? Colors.white : Colors.black,

          // Text styles.
          onBackground: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
          onSurface: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),

          // Backgrounds.
          background: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),
          surface: isDark ? const Color(0xFF292929) : const Color(0xFFf7f8fc),

          // Alerts.
          error: const Color(0xFFfb006d),
          onError: isDark ? const Color(0xFFffffff) : const Color(0xFF333333),
        ),
      ).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        highlightColor: main1,
        indicatorColor: main1,
        toggleableActiveColor: main1,
      );

  Color shift(Color c, double d) => ColorUtils.shiftHsl(c, d * (isDark ? -1 : 1));
}
