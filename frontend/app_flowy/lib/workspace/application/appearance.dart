import 'package:app_flowy/user/infrastructure/repos/user_setting_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_setting.pb.dart';
import 'package:flutter/material.dart';

class AppearanceSettingModel extends ChangeNotifier with EquatableMixin {
  AppearanceSettings setting;
  AppTheme _theme;
  AppLanguage _language;

  AppearanceSettingModel(this.setting)
      : _theme = AppTheme.fromName(name: setting.theme),
        _language = languageFromString(setting.language);

  AppTheme get theme => _theme;
  AppLanguage get language => _language;

  Future<void> save() async {
    await UserSettingReppsitory().setAppearanceSettings(setting);
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

  void setLanguage(AppLanguage language) {
    String languageString = stringFromLanguageName(language);

    if (setting.language != languageString) {
      _language = language;
      print('language changed to $languageString');
      setting.language = languageString;
      notifyListeners();
      save();
    }
  }
}
