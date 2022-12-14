import 'dart:async';

import 'package:app_flowy/user/application/user_settings_service.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_setting.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'appearance.freezed.dart';

/// [AppearanceSettingsCubit] is used to modify the appear setting of AppFlowy application. Includes the [Locale] and [AppTheme].
class AppearanceSettingsCubit extends Cubit<AppearanceSettingsState> {
  final AppearanceSettingsPB _setting;

  AppearanceSettingsCubit(AppearanceSettingsPB setting)
      : _setting = setting,
        super(AppearanceSettingsState.initial(
          setting.theme,
          setting.themeMode,
          setting.font,
          setting.monospaceFont,
          setting.locale,
        ));

  /// Updates the current theme and notify the listeners the theme was changed.
  /// Do nothing if the passed in themeType equal to the current theme type.
  // void setTheme(Brightness brightness) {
  //   if (state.theme.brightness == brightness) {
  //     return;
  //   }

  //   _setting.theme = themeTypeToString(brightness);
  //   _saveAppearanceSettings();

  //   emit(state.copyWith(
  //     theme: AppTheme.fromBrightness(
  //       brightness: _setting.themeMode,
  //       font: state.theme.font,
  //       monospaceFont: state.theme.monospaceFont,
  //     ),
  //   ));
  // }

  /// Updates the current theme and notify the listeners the theme was changed.
  /// Do nothing if the passed in themeType equal to the current theme type.
  void setThemeMode(ThemeMode themeMode) {
    if (state.themeMode == themeMode) {
      return;
    }

    _setting.themeMode = _themeModeToPB(themeMode);
    _saveAppearanceSettings();

    emit(state.copyWith(themeMode: themeMode));
  }

  /// Updates the current locale and notify the listeners the locale was changed
  /// Fallback to [en] locale If the newLocale is not supported.
  void setLocale(BuildContext context, Locale newLocale) {
    if (!context.supportedLocales.contains(newLocale)) {
      Log.warn("Unsupported locale: $newLocale, Fallback to locale: en");
      newLocale = const Locale('en');
    }

    context.setLocale(newLocale);

    if (state.locale != newLocale) {
      _setting.locale.languageCode = newLocale.languageCode;
      _setting.locale.countryCode = newLocale.countryCode ?? "";
      _saveAppearanceSettings();

      emit(state.copyWith(locale: newLocale));
    }
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

  /// Called when the application launch.
  /// Uses the device locale when open the application for the first time
  void readLocaleWhenAppLaunch(BuildContext context) {
    if (_setting.resetToDefault) {
      _setting.resetToDefault = false;
      _saveAppearanceSettings();
      setLocale(context, context.deviceLocale);
      return;
    }

    setLocale(context, state.locale);
  }

  Future<void> _saveAppearanceSettings() async {
    SettingsFFIService().setAppearanceSetting(_setting).then((result) {
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

@freezed
class AppearanceSettingsState with _$AppearanceSettingsState {
  const factory AppearanceSettingsState({
    required AppTheme theme,
    required AppTheme darkTheme,
    required ThemeMode themeMode,
    required Locale locale,
  }) = _AppearanceSettingsState;

  factory AppearanceSettingsState.initial(
    String themeName,
    ThemeModePB themeMode,
    String font,
    String monospaceFont,
    LocaleSettingsPB locale,
  ) =>
      AppearanceSettingsState(
        theme: AppTheme.fromBrightness(
          brightness: Brightness.light,
          font: font,
          monospaceFont: monospaceFont,
        ),
        darkTheme: AppTheme.fromBrightness(
          brightness: Brightness.dark,
          font: font,
          monospaceFont: monospaceFont,
        ),
        themeMode: _themeModeFromPB(themeMode),
        locale: Locale(locale.languageCode, locale.countryCode),
      );
}
