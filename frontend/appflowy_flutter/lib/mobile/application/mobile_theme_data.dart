// ThemeData in mobile
import 'package:flutter/material.dart';

ThemeData getMobileThemeData(
  Theme theme,
) {
  const mobileColorTheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2DA2F6), //primary 100
    onPrimary: Colors.white,
    // TODO(yijing): add color later
    secondary: Colors.white,
    onSecondary: Colors.white,
    error: Color(0xffFB006D),
    onError: Color(0xffFB006D),
    background: Colors.white,
    onBackground: Color(0xff2F3030), // title text
    outline: Color(0xffBDC0C5), //caption
    //Snack bar
    surface: Colors.white,
    onSurface: Color(0xff2F3030), // title text
  );
  return ThemeData(
    // color
    primaryColor: mobileColorTheme.primary, //primary 100
    primaryColorLight: const Color(0xFF57B5F8), //primary 80
    dividerColor: mobileColorTheme.outline, //caption
    scaffoldBackgroundColor: mobileColorTheme.background,
    appBarTheme: AppBarTheme(
      foregroundColor: mobileColorTheme.onBackground,
      backgroundColor: mobileColorTheme.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: mobileColorTheme.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
    ),
    // button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        shadowColor: MaterialStateProperty.all(null),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return const Color(0xFF57B5F8);
            }
            return mobileColorTheme.primary;
          },
        ),
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(
          mobileColorTheme.onBackground,
        ),
        backgroundColor: MaterialStateProperty.all(Colors.white),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        side: MaterialStateProperty.all(
          BorderSide(
            color: mobileColorTheme.outline,
            width: 0.5,
          ),
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16),
        ),
        // splash color
        overlayColor: MaterialStateProperty.all(
          Colors.grey[100],
        ),
      ),
    ),
    // text
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Color(0xFF57B5F8),
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.20,
        letterSpacing: 0.16,
      ),
      displayMedium: TextStyle(
        color: Color(0xff2F3030),
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.20,
        letterSpacing: 0.16,
      ),
      // H1 Semi 26
      displaySmall: TextStyle(
        color: Color(0xFF2F3030),
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.10,
        letterSpacing: 0.13,
      ),
      // body2 14 Regular
      bodyMedium: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.20,
        letterSpacing: 0.07,
      ),
      // blue text button
      labelMedium: TextStyle(
        color: Color(0xFF2DA2F6),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.20,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          width: 2,
          color: Color(0xFF2DA2F6), //primary 100
        ),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: mobileColorTheme.error),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: mobileColorTheme.error),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xffBDC0C5), //caption
        ),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
    colorScheme: mobileColorTheme,
  );
}
