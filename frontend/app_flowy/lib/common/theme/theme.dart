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

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFb061ff),
          selectionHandleColor: Color(0xFFb061ff),
        ),
        primaryIconTheme: const IconThemeData(color: Color(0xFF00bcf0)),
        canvasColor: Colors.grey.shade100,

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
      ).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        highlightColor: const Color(0xFF00bcf0),
        indicatorColor: const Color(0xFF00bcf0),
        toggleableActiveColor: const Color(0xFF00bcf0),
      );

  Color shift(Color c, double d) => ColorUtils.shiftHsl(c, d * (isDark ? -1 : 1));
}
