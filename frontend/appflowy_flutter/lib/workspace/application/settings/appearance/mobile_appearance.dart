// ThemeData in mobile
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

class MobileAppearance extends BaseAppearance {
  static const _primaryColor = Color(0xFF00BCF0); //primary 100
  static const _onBackgroundColor = Color(0xff2F3030); // text/title color
  static const _onSurfaceColor = Color(0xff676666); // text/body color
  static const _onSecondaryColor = Color(0xFFC5C7CB); // text/body2 color
  static const _hintColorInDarkMode = Color(0xff626262); // hint color

  @override
  ThemeData getThemeData(
    AppTheme appTheme,
    Brightness brightness,
    String fontFamily,
    String codeFontFamily,
  ) {
    assert(fontFamily.isNotEmpty);
    assert(codeFontFamily.isNotEmpty);

    final fontStyle = getFontStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
    );

    final codeFontStyle = getFontStyle(
      fontFamily: codeFontFamily,
    );

    final theme = brightness == Brightness.light
        ? appTheme.lightTheme
        : appTheme.darkTheme;

    final colorTheme = brightness == Brightness.light
        ? ColorScheme(
            brightness: brightness,
            primary: _primaryColor,
            onPrimary: Colors.white,
            // group card header background color
            primaryContainer: const Color(0xffF1F1F4), // primary 20
            // group card & property edit background color
            secondary: const Color(0xfff7f8fc), // shade 10
            onSecondary: _onSecondaryColor,
            // hidden group title & card text color
            tertiary: const Color(0xff858585), // for light text
            error: const Color(0xffFB006D),
            onError: const Color(0xffFB006D),
            background: Colors.white,
            onBackground: _onBackgroundColor,
            outline: const Color(0xffe3e3e3),
            outlineVariant: const Color(0xffCBD5E0).withOpacity(0.24),
            //Snack bar
            surface: Colors.white,
            onSurface: _onSurfaceColor, // text/body color
            surfaceVariant: const Color.fromARGB(255, 216, 216, 216),
          )
        : ColorScheme(
            brightness: brightness,
            primary: _primaryColor,
            onPrimary: Colors.black,
            secondary: const Color(0xff2d2d2d), //temp
            onSecondary: Colors.white,
            tertiary: const Color(0xff858585), // temp
            error: const Color(0xffFB006D),
            onError: const Color(0xffFB006D),
            background: const Color(0xff121212), // temp
            onBackground: Colors.white,
            outline: _hintColorInDarkMode,
            outlineVariant: Colors.black,
            //Snack bar
            surface: const Color(0xFF171A1F),
            onSurface: const Color(0xffC5C6C7), // text/body color
          );
    final hintColor = brightness == Brightness.light
        ? const Color(0x991F2329)
        : _hintColorInDarkMode;

    return ThemeData(
      // color
      useMaterial3: false,

      primaryColor: colorTheme.primary, //primary 100
      primaryColorLight: const Color(0xFF57B5F8), //primary 80
      dividerColor: colorTheme.outline, //caption
      hintColor: hintColor,
      disabledColor: colorTheme.outline,
      scaffoldBackgroundColor: colorTheme.background,
      appBarTheme: AppBarTheme(
        foregroundColor: colorTheme.onBackground,
        backgroundColor: colorTheme.background,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorTheme.onBackground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
        ),
        shadowColor: colorTheme.outlineVariant,
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorTheme.primary;
          }
          return colorTheme.outline;
        }),
      ),
      // button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          fixedSize: MaterialStateProperty.all(const Size.fromHeight(48)),
          elevation: MaterialStateProperty.all(0),
          textStyle: MaterialStateProperty.all(
            TextStyle(
              fontSize: 14,
              fontFamily: fontStyle.fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          shadowColor: MaterialStateProperty.all(null),
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return _primaryColor;
              }
              return colorTheme.primary;
            },
          ),
          foregroundColor: MaterialStateProperty.all(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            TextStyle(
              fontSize: 14,
              fontFamily: fontStyle.fontFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
          foregroundColor: MaterialStateProperty.all(
            colorTheme.onBackground,
          ),
          backgroundColor: MaterialStateProperty.all(colorTheme.background),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          side: MaterialStateProperty.all(
            BorderSide(
              color: colorTheme.outline,
              width: 0.5,
            ),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            fontStyle,
          ),
        ),
      ),
      // text
      fontFamily: fontStyle.fontFamily,
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          color: _primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.20,
          letterSpacing: 0.16,
        ),
        displayMedium: fontStyle.copyWith(
          color: colorTheme.onBackground,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.20,
          letterSpacing: 0.16,
        ),
        // H1 Semi 26
        displaySmall: fontStyle.copyWith(
          color: colorTheme.onBackground,
          fontWeight: FontWeight.w600,
          height: 1.10,
          letterSpacing: 0.13,
        ),
        // body2 14 Regular
        bodyMedium: fontStyle.copyWith(
          color: colorTheme.onBackground,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.07,
        ),
        // Trash empty title
        labelLarge: fontStyle.copyWith(
          color: colorTheme.onBackground,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        // setting item title
        labelMedium: fontStyle.copyWith(
          color: colorTheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        // setting group title
        labelSmall: fontStyle.copyWith(
          color: colorTheme.onBackground,
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
          borderSide: BorderSide(color: colorTheme.error),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorTheme.error),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorTheme.outline,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
      ),
      colorScheme: colorTheme,
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
          code: codeFontStyle.copyWith(
            color: theme.shader3,
          ),
          callout: fontStyle.copyWith(
            fontSize: FontSizes.s11,
            color: theme.shader3,
          ),
          calloutBGColor: theme.hoverBG3,
          tableCellBGColor: theme.surface,
          caption: fontStyle.copyWith(
            fontSize: FontSizes.s11,
            fontWeight: FontWeight.w400,
            color: theme.hint,
          ),
        ),
        ToolbarColorExtension.fromBrightness(brightness),
      ],
    );
  }
}
