import 'dart:async';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'appearance_cubit.freezed.dart';

/// [AppearanceSettingsCubit] is used to modify the appearance of AppFlowy.
/// It includes:
/// - [AppTheme]
/// - [ThemeMode]
/// - [TextStyle]'s
/// - [Locale]
/// - [UserDateFormatPB]
/// - [UserTimeFormatPB]
///
class AppearanceSettingsCubit extends Cubit<AppearanceSettingsState> {
  final AppearanceSettingsPB _appearanceSettings;
  final DateTimeSettingsPB _dateTimeSettings;

  AppearanceSettingsCubit(
    AppearanceSettingsPB appearanceSettings,
    DateTimeSettingsPB dateTimeSettings,
    AppTheme appTheme,
  )   : _appearanceSettings = appearanceSettings,
        _dateTimeSettings = dateTimeSettings,
        super(
          AppearanceSettingsState.initial(
            appTheme,
            appearanceSettings.themeMode,
            appearanceSettings.font,
            appearanceSettings.monospaceFont,
            appearanceSettings.layoutDirection,
            appearanceSettings.textDirection,
            appearanceSettings.locale,
            appearanceSettings.isMenuCollapsed,
            appearanceSettings.menuOffset,
            dateTimeSettings.dateFormat,
            dateTimeSettings.timeFormat,
            dateTimeSettings.timezoneId,
          ),
        );

  /// Update selected theme in the user's settings and emit an updated state
  /// with the AppTheme named [themeName].
  Future<void> setTheme(String themeName) async {
    _appearanceSettings.theme = themeName;
    _saveAppearanceSettings();
    emit(state.copyWith(appTheme: await AppTheme.fromName(themeName)));
  }

  /// Reset the current user selected theme back to the default
  Future<void> resetTheme() =>
      setTheme(DefaultAppearanceSettings.kDefaultThemeName);

  /// Update the theme mode in the user's settings and emit an updated state.
  void setThemeMode(ThemeMode themeMode) {
    _appearanceSettings.themeMode = _themeModeToPB(themeMode);
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
    _appearanceSettings.layoutDirection = layoutDirection.toLayoutDirectionPB();
    _saveAppearanceSettings();
    emit(state.copyWith(layoutDirection: layoutDirection));
  }

  void setTextDirection(AppFlowyTextDirection? textDirection) {
    _appearanceSettings.textDirection =
        textDirection?.toTextDirectionPB() ?? TextDirectionPB.FALLBACK;
    _saveAppearanceSettings();
    emit(state.copyWith(textDirection: textDirection));
  }

  /// Update selected font in the user's settings and emit an updated state
  /// with the font name.
  void setFontFamily(String fontFamilyName) {
    _appearanceSettings.font = fontFamilyName;
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
      _appearanceSettings.locale.languageCode = newLocale.languageCode;
      _appearanceSettings.locale.countryCode = newLocale.countryCode ?? "";
      _saveAppearanceSettings();
      emit(state.copyWith(locale: newLocale));
    }
  }

  // Saves the menus current visibility
  void saveIsMenuCollapsed(bool collapsed) {
    _appearanceSettings.isMenuCollapsed = collapsed;
    _saveAppearanceSettings();
  }

  // Saves the current resize offset of the menu
  void saveMenuOffset(double offset) {
    _appearanceSettings.menuOffset = offset;
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
      _appearanceSettings.settingKeyValue.remove(key);
    }

    if (_appearanceSettings.settingKeyValue[key] != value) {
      if (value == null) {
        _appearanceSettings.settingKeyValue.remove(key);
      } else {
        _appearanceSettings.settingKeyValue[key] = value;
      }
    }
    _saveAppearanceSettings();
  }

  String? getValue(String key) {
    if (key.isEmpty) {
      Log.warn("The key should not be empty");
      return null;
    }
    return _appearanceSettings.settingKeyValue[key];
  }

  /// Called when the application launches.
  /// Uses the device locale when the application is opened for the first time.
  void readLocaleWhenAppLaunch(BuildContext context) {
    if (_appearanceSettings.resetToDefault) {
      _appearanceSettings.resetToDefault = false;
      _saveAppearanceSettings();
      setLocale(context, context.deviceLocale);
      return;
    }

    setLocale(context, state.locale);
  }

  void setDateFormat(UserDateFormatPB format) {
    _dateTimeSettings.dateFormat = format;
    _saveDateTimeSettings();
    emit(state.copyWith(dateFormat: format));
  }

  void setTimeFormat(UserTimeFormatPB format) {
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
    UserSettingsBackendService()
        .setAppearanceSetting(_appearanceSettings)
        .then((result) {
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
    required UserDateFormatPB dateFormat,
    required UserTimeFormatPB timeFormat,
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
    UserDateFormatPB dateFormat,
    UserTimeFormatPB timeFormat,
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
    return getIt<BaseAppearance>().getThemeData(
      appTheme,
      brightness,
      font,
      monospaceFont,
    );
  }
}
