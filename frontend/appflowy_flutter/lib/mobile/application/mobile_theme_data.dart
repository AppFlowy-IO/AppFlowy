// ThemeData in mobile
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

const _primaryColor = Color(0xFF2DA2F6); //primary 100
const _onBackgroundColor = Color(0xff2F3030); // text/title color
const _onSurfaceColor = Color(0xff676666); // text/body color
const _onSecondaryColor = Color(0xFFC5C7CB); // text/body2 color

// TODO(yijing): improve theme color before release
ThemeData getMobileThemeData(
  Brightness brightness,
  FlowyColorScheme theme,
  String fontFamily,
  String monospaceFontFamily,
) {
  final mobileColorTheme = (brightness == Brightness.light)
      ? ColorScheme(
          brightness: brightness,
          primary: _primaryColor,
          onPrimary: Colors.white,
          // TODO(yijing): add color later
          secondary: Colors.white,
          onSecondary: _onSecondaryColor,
          error: const Color(0xffFB006D),
          onError: const Color(0xffFB006D),
          background: Colors.white,
          onBackground: _onBackgroundColor,
          outline: const Color(0xffBDC0C5), //caption
          outlineVariant: const Color(0xffCBD5E0).withOpacity(0.24),
          //Snack bar
          surface: Colors.white,
          onSurface: _onSurfaceColor, // text/body color
          surfaceVariant: const Color.fromARGB(255, 216, 216, 216),
        )
      : ColorScheme(
          brightness: brightness,
          primary: _primaryColor,
          onPrimary: Colors.white,
          // TODO(yijing): add color later
          secondary: Colors.black,
          onSecondary: Colors.white,
          error: const Color(0xffFB006D),
          onError: const Color(0xffFB006D),
          background: const Color(0xff1C1C1E), // BG/Secondary color
          onBackground: Colors.white,
          outline: const Color(0xff96989C), //caption
          outlineVariant: Colors.black,
          //Snack bar
          surface: const Color(0xff2F3030),
          onSurface: const Color(0xffC5C6C7), // text/body color
        );

  return ThemeData(
    // color
    primaryColor: mobileColorTheme.primary, //primary 100
    primaryColorLight: const Color(0xFF57B5F8), //primary 80
    dividerColor: mobileColorTheme.outline, //caption
    hintColor: mobileColorTheme.outline,
    disabledColor: mobileColorTheme.outline,
    scaffoldBackgroundColor: mobileColorTheme.background,
    appBarTheme: AppBarTheme(
      foregroundColor: mobileColorTheme.onBackground,
      backgroundColor: mobileColorTheme.background,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: mobileColorTheme.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
      shadowColor: mobileColorTheme.outlineVariant,
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return mobileColorTheme.primary;
        }
        return mobileColorTheme.outline;
      }),
    ),
    // button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        fixedSize: MaterialStateProperty.all(const Size.fromHeight(48)),
        elevation: MaterialStateProperty.all(0),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        foregroundColor: MaterialStateProperty.all(
          mobileColorTheme.onBackground,
        ),
        backgroundColor: MaterialStateProperty.all(mobileColorTheme.background),
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
          const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        // splash color
        overlayColor: MaterialStateProperty.all(
          Colors.grey[100],
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
      ),
    ),
    // text
    fontFamily: 'Poppins',
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: Color(0xFF57B5F8),
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.20,
        letterSpacing: 0.16,
      ),
      displayMedium: TextStyle(
        color: mobileColorTheme.onBackground,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.20,
        letterSpacing: 0.16,
      ),
      // H1 Semi 26
      displaySmall: TextStyle(
        color: mobileColorTheme.onBackground,
        fontWeight: FontWeight.w600,
        height: 1.10,
        letterSpacing: 0.13,
      ),
      // body2 14 Regular
      bodyMedium: TextStyle(
        color: mobileColorTheme.onBackground,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.20,
        letterSpacing: 0.07,
      ),
      // Trash empty title
      labelLarge: TextStyle(
        color: mobileColorTheme.onBackground,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      // setting item title
      labelMedium: TextStyle(
        color: mobileColorTheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      // setting group title
      labelSmall: TextStyle(
        color: mobileColorTheme.onBackground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(8),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          width: 2,
          color: _primaryColor,
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
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: mobileColorTheme.outline,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
    ),
    colorScheme: mobileColorTheme,
    indicatorColor: Colors.blue,
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
        textColor: theme.text,
        greyHover: theme.hoverBG1,
        greySelect: theme.bg3,
        lightGreyHover: theme.hoverBG3,
        toggleOffFill: theme.shader5,
        progressBarBGColor: theme.progressBarBGColor,
        toggleButtonBGColor: theme.toggleButtonBGColor,
        calendarWeekendBGColor: theme.calendarWeekendBGColor,
        gridRowCountColor: theme.gridRowCountColor,
        code: getFontStyle(
          fontFamily: monospaceFontFamily,
          fontColor: theme.shader3,
        ),
        callout: getFontStyle(
          fontFamily: fontFamily,
          fontSize: FontSizes.s11,
          fontColor: theme.shader3,
        ),
        calloutBGColor: theme.hoverBG3,
        tableCellBGColor: theme.surface,
        caption: getFontStyle(
          fontFamily: fontFamily,
          fontSize: FontSizes.s11,
          fontWeight: FontWeight.w400,
          fontColor: theme.hint,
        ),
      ),
    ],
  );
}
