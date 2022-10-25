import 'dart:async';

import 'package:app_flowy/user/application/user_settings_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_setting.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// [AppearanceSetting] is used to modify the appear setting of AppFlowy application. Including the [Locale], [AppTheme], etc.
class AppearanceSetting extends ChangeNotifier with EquatableMixin {
  final AppearanceSettingsPB _setting;
  AppTheme _theme;
  Locale _locale;

  AppearanceSetting(AppearanceSettingsPB setting)
      : _setting = setting,
        _theme = AppTheme.fromName(name: setting.theme),
        _locale = Locale(
          setting.locale.languageCode,
          setting.locale.countryCode,
        );

  /// Returns the current [AppTheme]
  AppTheme get theme => _theme;

  /// Returns the current [Locale]
  Locale get locale => _locale;

  /// Updates the current theme and notify the listeners the theme was changed.
  /// Do nothing if the passed in themeType equal to the current theme type.
  ///
  void setTheme(ThemeType themeType) {
    if (_theme.ty == themeType) {
      return;
    }

    _theme = AppTheme.fromType(themeType);
    _setting.theme = themeTypeToString(themeType);
    _saveAppearSetting();

    notifyListeners();
  }

  /// Updates the current locale and notify the listeners the locale was changed
  /// Fallback to [en] locale If the newLocale is not supported.
  ///
  void setLocale(BuildContext context, Locale newLocale) {
    if (!context.supportedLocales.contains(newLocale)) {
      Log.warn("Unsupported locale: $newLocale, Fallback to locale: en");
      newLocale = const Locale('en');
    }

    context.setLocale(newLocale);

    if (_locale != newLocale) {
      _locale = newLocale;
      _setting.locale.languageCode = _locale.languageCode;
      _setting.locale.countryCode = _locale.countryCode ?? "";
      _saveAppearSetting();

      notifyListeners();
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
    _saveAppearSetting();
    notifyListeners();
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
      _saveAppearSetting();
      setLocale(context, context.deviceLocale);
      return;
    }

    setLocale(context, _locale);
  }

  Future<void> _saveAppearSetting() async {
    SettingsFFIService().setAppearanceSetting(_setting).then((result) {
      result.fold(
        (l) => null,
        (error) => Log.error(error),
      );
    });
  }

  @override
  List<Object> get props {
    return [_setting.hashCode];
  }
}
