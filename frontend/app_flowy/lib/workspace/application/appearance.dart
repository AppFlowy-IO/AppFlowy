import 'package:app_flowy/user/infrastructure/repos/user_setting_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_setting.pb.dart';
import 'package:flutter/material.dart';

class AppearanceSettingModel extends ChangeNotifier with EquatableMixin {
  AppearanceSettings setting;
  AppTheme _theme;

  AppearanceSettingModel(this.setting) : _theme = AppTheme.fromName(name: setting.theme);
  AppTheme get theme => _theme;

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

  void setLanguage(String language) {
    if (setting.language != language) {
      setting.language = language;
      notifyListeners();
      save();
    }
  }
}
