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
        super(AppearanceSettingsState.initial(setting.theme, setting.locale));

  /// Updates the current theme and notify the listeners the theme was changed.
  /// Do nothing if the passed in themeType equal to the current theme type.
  void setTheme(ThemeType themeType) {
    if (state.theme.ty == themeType) {
      return;
    }

    _setting.theme = themeTypeToString(themeType);
    _saveAppearanceSettings();

    emit(state.copyWith(theme: AppTheme.fromType(themeType)));
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

@freezed
class AppearanceSettingsState with _$AppearanceSettingsState {
  const factory AppearanceSettingsState({
    required AppTheme theme,
    required Locale locale,
  }) = _AppearanceSettingsState;

  factory AppearanceSettingsState.initial(
    String themeName,
    LocaleSettingsPB locale,
  ) =>
      AppearanceSettingsState(
        theme: AppTheme.fromName(name: themeName),
        locale: Locale(locale.languageCode, locale.countryCode),
      );
}
