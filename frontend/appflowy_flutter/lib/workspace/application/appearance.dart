import 'dart:async';

import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/mobile_theme_data.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_fonts/google_fonts.dart';

part 'appearance.freezed.dart';

const _white = Color(0xFFFFFFFF);

/// [AppearanceSettingsCubit] is used to modify the appearance of AppFlowy.
/// It includes the [AppTheme], [ThemeMode], [TextStyles] and [Locale].
class AppearanceSettingsCubit extends Cubit<AppearanceSettingsState> {
  final AppearanceSettingsPB _setting;
  final DateTimeSettingsPB _dateTimeSettings;

  AppearanceSettingsCubit(
    AppearanceSettingsPB setting,
    DateTimeSettingsPB dateTimeSettings,
    AppTheme appTheme,
  )   : _setting = setting,
        _dateTimeSettings = dateTimeSettings,
        super(
          AppearanceSettingsState.initial(
            appTheme,
            setting.themeMode,
            setting.font,
            setting.monospaceFont,
            setting.layoutDirection,
            setting.textDirection,
            setting.locale,
            setting.isMenuCollapsed,
            setting.menuOffset,
            dateTimeSettings.dateFormat,
            dateTimeSettings.timeFormat,
            dateTimeSettings.timezoneId,
          ),
        );

  /// Update selected theme in the user's settings and emit an updated state
  /// with the AppTheme named [themeName].
  Future<void> setTheme(String themeName) async {
    _setting.theme = themeName;
    _saveAppearanceSettings();
    emit(state.copyWith(appTheme: await AppTheme.fromName(themeName)));
  }

  /// Reset the current user selected theme back to the default
  Future<void> resetTheme() =>
      setTheme(DefaultAppearanceSettings.kDefaultThemeName);

  /// Update the theme mode in the user's settings and emit an updated state.
  void setThemeMode(ThemeMode themeMode) {
    _setting.themeMode = _themeModeToPB(themeMode);
    _saveAppearanceSettings();
    emit(state.copyWith(themeMode: themeMode));
  }

  /// Resets the current brightness setting
  void resetThemeMode() =>
      setThemeMode(DefaultAppearanceSettings.kDefaultThemeMode);

  /// Toggle the theme mode
  void toggleThemeMode() {
    final currentThemeMode = state.themeMode;
    setThemeMode(
      currentThemeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setLayoutDirection(LayoutDirection layoutDirection) {
    _setting.layoutDirection = layoutDirection.toLayoutDirectionPB();
    _saveAppearanceSettings();
    emit(state.copyWith(layoutDirection: layoutDirection));
  }

  void setTextDirection(AppFlowyTextDirection? textDirection) {
    _setting.textDirection =
        textDirection?.toTextDirectionPB() ?? TextDirectionPB.FALLBACK;
    _saveAppearanceSettings();
    emit(state.copyWith(textDirection: textDirection));
  }

  /// Update selected font in the user's settings and emit an updated state
  /// with the font name.
  void setFontFamily(String fontFamilyName) {
    _setting.font = fontFamilyName;
    _saveAppearanceSettings();
    emit(state.copyWith(font: fontFamilyName));
  }

  /// Resets the current font family for the user preferences
  void resetFontFamily() =>
      setFontFamily(DefaultAppearanceSettings.kDefaultFontFamily);

  /// Updates the current locale and notify the listeners the locale was
  /// changed. Fallback to [en] locale if [newLocale] is not supported.
  void setLocale(BuildContext context, Locale newLocale) {
    if (!context.supportedLocales.contains(newLocale)) {
      // Log.warn("Unsupported locale: $newLocale, Fallback to locale: en");
      newLocale = const Locale('en');
    }

    context.setLocale(newLocale).catchError((e) {
      Log.warn('Catch error in setLocale: $e}');
    });

    if (state.locale != newLocale) {
      _setting.locale.languageCode = newLocale.languageCode;
      _setting.locale.countryCode = newLocale.countryCode ?? "";
      _saveAppearanceSettings();
      emit(state.copyWith(locale: newLocale));
    }
  }

  // Saves the menus current visibility
  void saveIsMenuCollapsed(bool collapsed) {
    _setting.isMenuCollapsed = collapsed;
    _saveAppearanceSettings();
  }

  // Saves the current resize offset of the menu
  void saveMenuOffset(double offset) {
    _setting.menuOffset = offset;
    _saveAppearanceSettings();
  }

  /// Saves key/value setting to disk.
  /// Removes the key if the passed in value is null
  void setKeyValue(String key, String? value) {
    if (key.isEmpty) {
      Log.warn("The key should not be empty");
      return;
    }

    if (value == null) {
      _setting.settingKeyValue.remove(key);
    }

    if (_setting.settingKeyValue[key] != value) {
      if (value == null) {
        _setting.settingKeyValue.remove(key);
      } else {
        _setting.settingKeyValue[key] = value;
      }
    }
    _saveAppearanceSettings();
  }

  String? getValue(String key) {
    if (key.isEmpty) {
      Log.warn("The key should not be empty");
      return null;
    }
    return _setting.settingKeyValue[key];
  }

  /// Called when the application launches.
  /// Uses the device locale when the application is opened for the first time.
  void readLocaleWhenAppLaunch(BuildContext context) {
    if (_setting.resetToDefault) {
      _setting.resetToDefault = false;
      _saveAppearanceSettings();
      setLocale(context, context.deviceLocale);
      return;
    }

    setLocale(context, state.locale);
  }

  void setDateFormat(DateFormatPB format) {
    _dateTimeSettings.dateFormat = format;
    _saveDateTimeSettings();
    emit(state.copyWith(dateFormat: format));
  }

  void setTimeFormat(TimeFormatPB format) {
    _dateTimeSettings.timeFormat = format;
    _saveDateTimeSettings();
    emit(state.copyWith(timeFormat: format));
  }

  Future<void> _saveDateTimeSettings() async {
    UserSettingsBackendService()
        .setDateTimeSettings(_dateTimeSettings)
        .then((result) {
      result.fold(
        (error) => Log.error(error),
        (_) => null,
      );
    });
  }

  Future<void> _saveAppearanceSettings() async {
    UserSettingsBackendService().setAppearanceSetting(_setting).then((result) {
      result.fold(
        (l) => null,
        (error) => Log.error(error),
      );
    });
  }
}

ThemeMode _themeModeFromPB(ThemeModePB themeModePB) {
  switch (themeModePB) {
    case ThemeModePB.Light:
      return ThemeMode.light;
    case ThemeModePB.Dark:
      return ThemeMode.dark;
    case ThemeModePB.System:
    default:
      return ThemeMode.system;
  }
}

ThemeModePB _themeModeToPB(ThemeMode themeMode) {
  switch (themeMode) {
    case ThemeMode.light:
      return ThemeModePB.Light;
    case ThemeMode.dark:
      return ThemeModePB.Dark;
    case ThemeMode.system:
    default:
      return ThemeModePB.System;
  }
}

enum LayoutDirection {
  ltrLayout,
  rtlLayout;

  static LayoutDirection fromLayoutDirectionPB(
    LayoutDirectionPB layoutDirectionPB,
  ) =>
      layoutDirectionPB == LayoutDirectionPB.RTLLayout
          ? LayoutDirection.rtlLayout
          : LayoutDirection.ltrLayout;

  LayoutDirectionPB toLayoutDirectionPB() => this == LayoutDirection.rtlLayout
      ? LayoutDirectionPB.RTLLayout
      : LayoutDirectionPB.LTRLayout;
}

enum AppFlowyTextDirection {
  ltr,
  rtl,
  auto;

  static AppFlowyTextDirection? fromTextDirectionPB(
    TextDirectionPB? textDirectionPB,
  ) {
    switch (textDirectionPB) {
      case TextDirectionPB.LTR:
        return AppFlowyTextDirection.ltr;
      case TextDirectionPB.RTL:
        return AppFlowyTextDirection.rtl;
      case TextDirectionPB.AUTO:
        return AppFlowyTextDirection.auto;
      default:
        return null;
    }
  }

  TextDirectionPB toTextDirectionPB() {
    switch (this) {
      case AppFlowyTextDirection.ltr:
        return TextDirectionPB.LTR;
      case AppFlowyTextDirection.rtl:
        return TextDirectionPB.RTL;
      case AppFlowyTextDirection.auto:
        return TextDirectionPB.AUTO;
      default:
        return TextDirectionPB.FALLBACK;
    }
  }
}

@freezed
class AppearanceSettingsState with _$AppearanceSettingsState {
  const AppearanceSettingsState._();

  const factory AppearanceSettingsState({
    required AppTheme appTheme,
    required ThemeMode themeMode,
    required String font,
    required String monospaceFont,
    required LayoutDirection layoutDirection,
    required AppFlowyTextDirection? textDirection,
    required Locale locale,
    required bool isMenuCollapsed,
    required double menuOffset,
    required DateFormatPB dateFormat,
    required TimeFormatPB timeFormat,
    required String timezoneId,
  }) = _AppearanceSettingsState;

  factory AppearanceSettingsState.initial(
    AppTheme appTheme,
    ThemeModePB themeModePB,
    String font,
    String monospaceFont,
    LayoutDirectionPB layoutDirectionPB,
    TextDirectionPB? textDirectionPB,
    LocaleSettingsPB localePB,
    bool isMenuCollapsed,
    double menuOffset,
    DateFormatPB dateFormat,
    TimeFormatPB timeFormat,
    String timezoneId,
  ) {
    return AppearanceSettingsState(
      appTheme: appTheme,
      font: font,
      monospaceFont: monospaceFont,
      layoutDirection: LayoutDirection.fromLayoutDirectionPB(layoutDirectionPB),
      textDirection: AppFlowyTextDirection.fromTextDirectionPB(textDirectionPB),
      themeMode: _themeModeFromPB(themeModePB),
      locale: Locale(localePB.languageCode, localePB.countryCode),
      isMenuCollapsed: isMenuCollapsed,
      menuOffset: menuOffset,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      timezoneId: timezoneId,
    );
  }

  ThemeData get lightTheme => _getThemeData(Brightness.light);
  ThemeData get darkTheme => _getThemeData(Brightness.dark);

  ThemeData _getThemeData(Brightness brightness) {
    // Poppins and SF Mono are not well supported in some languages, so use the
    // built-in font for the following languages.
    final useBuiltInFontLanguages = [
      const Locale('zh', 'CN'),
      const Locale('zh', 'TW'),
    ];
    String fontFamily = font;
    String monospaceFontFamily = monospaceFont;
    if (useBuiltInFontLanguages.contains(locale)) {
      fontFamily = '';
      monospaceFontFamily = '';
    }

    final theme = brightness == Brightness.light
        ? appTheme.lightTheme
        : appTheme.darkTheme;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: theme.primary,
      onPrimary: theme.onPrimary,
      primaryContainer: theme.main2,
      onPrimaryContainer: _white,
      // page title hover color
      secondary: theme.hoverBG1,
      onSecondary: theme.shader1,
      // setting value hover color
      secondaryContainer: theme.selector,
      onSecondaryContainer: theme.topbarBg,
      tertiary: theme.shader7,
      // Editor: toolbarColor
      onTertiary: theme.toolbarColor,
      tertiaryContainer: theme.questionBubbleBG,
      background: theme.surface,
      onBackground: theme.text,
      surface: theme.surface,
      // text&icon color when it is hovered
      onSurface: theme.hoverFG,
      // grey hover color
      inverseSurface: theme.hoverBG3,
      onError: theme.onPrimary,
      error: theme.red,
      outline: theme.shader4,
      surfaceVariant: theme.sidebarBg,
      shadow: theme.shadow,
    );

    const Set<MaterialState> scrollbarInteractiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.dragged,
    };

    if (PlatformExtension.isMobile) {
      // Mobile version has only one theme(light mode) for now.
      // The desktop theme and the mobile theme are independent.
      final mobileThemeData = getMobileThemeData();
      return mobileThemeData;
    }

    // Due to Desktop version has multiple themes, it relies on the current theme to build the ThemeData
    final desktopThemeData = ThemeData(
      brightness: brightness,
      dialogBackgroundColor: theme.surface,
      textTheme: _getTextTheme(fontFamily: fontFamily, fontColor: theme.text),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.main2,
        selectionHandleColor: theme.main2,
      ),
      iconTheme: IconThemeData(color: theme.icon),
      tooltipTheme: TooltipThemeData(
        textStyle: _getFontStyle(
          fontFamily: fontFamily,
          fontSize: FontSizes.s11,
          fontWeight: FontWeight.w400,
          fontColor: theme.surface,
        ),
      ),
      scaffoldBackgroundColor: theme.surface,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.any(scrollbarInteractiveStates.contains)) {
            return theme.shader7;
          }
          return theme.shader5;
        }),
        thickness: MaterialStateProperty.resolveWith((states) {
          if (states.any(scrollbarInteractiveStates.contains)) {
            return 4;
          }
          return 3.0;
        }),
        crossAxisMargin: 0.0,
        mainAxisMargin: 6.0,
        radius: Corners.s10Radius,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //dropdown menu color
      canvasColor: theme.surface,
      dividerColor: theme.divider,
      hintColor: theme.hint,
      //action item hover color
      hoverColor: theme.hoverBG2,
      disabledColor: theme.shader4,
      highlightColor: theme.main1,
      indicatorColor: theme.main1,
      cardColor: theme.input,
      colorScheme: colorScheme,
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
          code: _getFontStyle(
            fontFamily: monospaceFontFamily,
            fontColor: theme.shader3,
          ),
          callout: _getFontStyle(
            fontFamily: fontFamily,
            fontSize: FontSizes.s11,
            fontColor: theme.shader3,
          ),
          calloutBGColor: theme.hoverBG3,
          tableCellBGColor: theme.surface,
          caption: _getFontStyle(
            fontFamily: fontFamily,
            fontSize: FontSizes.s11,
            fontWeight: FontWeight.w400,
            fontColor: theme.hint,
          ),
        ),
      ],
    );
    return desktopThemeData;
  }

  TextStyle _getFontStyle({
    required String fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? fontColor,
    double? letterSpacing,
    double? lineHeight,
  }) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize ?? FontSizes.s12,
        color: fontColor,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: (fontSize ?? FontSizes.s12) * (letterSpacing ?? 0.005),
        height: lineHeight,
      );
    } catch (e) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? FontSizes.s12,
        color: fontColor,
        fontWeight: fontWeight ?? FontWeight.w500,
        fontFamilyFallback: const ["Noto Color Emoji"],
        letterSpacing: (fontSize ?? FontSizes.s12) * (letterSpacing ?? 0.005),
        height: lineHeight,
      );
    }
  }

  TextTheme _getTextTheme({
    required String fontFamily,
    required Color fontColor,
  }) {
    return TextTheme(
      displayLarge: _getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s32,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
        lineHeight: 42.0,
      ), // h2
      displayMedium: _getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s24,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
        lineHeight: 34.0,
      ), // h3
      displaySmall: _getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s20,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
        lineHeight: 28.0,
      ), // h4
      titleLarge: _getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s18,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
      ), // title
      titleMedium: _getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s16,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
      ), // heading
      titleSmall: _getFontStyle(
        fontFamily: fontFamily,
        fontSize: FontSizes.s14,
        fontColor: fontColor,
        fontWeight: FontWeight.w600,
      ), // subheading
      bodyMedium: _getFontStyle(
        fontFamily: fontFamily,
        fontColor: fontColor,
      ), // body-regular
      bodySmall: _getFontStyle(
        fontFamily: fontFamily,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
      ), // body-thin
    );
  }
}
