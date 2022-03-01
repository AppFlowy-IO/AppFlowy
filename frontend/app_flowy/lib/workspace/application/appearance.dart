import 'package:app_flowy/user/application/user_settings_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_setting.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:async/async.dart';

class AppearanceSettingModel extends ChangeNotifier with EquatableMixin {
  AppearanceSettings setting;
  AppTheme _theme;
  Locale _locale;
  CancelableOperation? _saveOperation;

  AppearanceSettingModel(this.setting)
      : _theme = AppTheme.fromName(name: setting.theme),
        _locale = Locale(setting.locale.languageCode, setting.locale.countryCode);

  AppTheme get theme => _theme;
  Locale get locale => _locale;

  Future<void> save() async {
    _saveOperation?.cancel;
    _saveOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 1), () async {
        await UserSettingsService().setAppearanceSettings(setting);
      }),
    );
  }

  @override
  List<Object> get props {
    return [setting.hashCode];
  }

  void swapTheme() {
    final themeType = (_theme.ty == ThemeType.light ? ThemeType.dark : ThemeType.light);

    if (_theme.ty != themeType) {
      _theme = AppTheme.fromType(themeType);
      setting.theme = themeTypeToString(themeType);
      notifyListeners();
      save();
    }
  }

  void setLocale(BuildContext context, Locale newLocale) {
    if (_locale != newLocale) {
      if (!context.supportedLocales.contains(newLocale)) {
        Log.warn("Unsupported locale: $newLocale");
        newLocale = const Locale('en');
        Log.debug("Fallback to locale: $newLocale");
      }

      context.setLocale(newLocale);
      _locale = newLocale;
      setting.locale.languageCode = _locale.languageCode;
      setting.locale.countryCode = _locale.countryCode ?? "";
      notifyListeners();
      save();
    }
  }

  void readLocaleWhenAppLaunch(BuildContext context) {
    if (setting.resetAsDefault) {
      setting.resetAsDefault = false;
      save();

      setLocale(context, context.deviceLocale);
    }
  }
}
