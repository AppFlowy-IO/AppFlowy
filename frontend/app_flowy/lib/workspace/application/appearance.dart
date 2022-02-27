import 'package:app_flowy/user/infrastructure/repos/user_setting_repo.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_setting.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:async/async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/theme/theme.dart';

part 'appearance.freezed.dart';

class AppearanceSettingsCubit extends Cubit<AppearanceSettingsState> {
  AppearanceSettingsCubit(this.settings)
      : super(AppearanceSettingsState(
          theme: FlowyTheme.fromName(settings.theme),
          locale: Locale(settings.locale.languageCode, settings.locale.countryCode),
        ));

  AppearanceSettings settings;
  CancelableOperation? _saveOperation;

  void swapTheme() {
    final _newTheme = FlowyTheme(state.theme.isDark ? DefaultThemes.light : DefaultThemes.dark);
    emit(state.copyWith(theme: _newTheme));
    settings.theme = state.theme.theme.toString();
    _save();
  }

  void setLocale(BuildContext context, Locale newLocale) {
    if (state.locale != newLocale) {
      if (!context.supportedLocales.contains(newLocale)) {
        Log.error("Unsupported locale: $newLocale");
        newLocale = const Locale('en');
        Log.debug("Fallback to locale: $newLocale");
      }

      context.setLocale(newLocale);
      emit(state.copyWith(locale: newLocale));
      settings.locale.languageCode = state.locale.languageCode;
      settings.locale.countryCode = state.locale.countryCode ?? "";
      _save();
    }
  }

  void loadLocale(BuildContext context) {
    if (settings.resetAsDefault) {
      settings.resetAsDefault = false;
      _save();

      setLocale(context, context.deviceLocale);
    }
  }

  Future<void> _save() async {
    _saveOperation?.cancel;
    _saveOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 1), () async {
        await UserSettingReppsitory().setAppearanceSettings(settings);
      }),
    );
  }
}

@freezed
class AppearanceSettingsState with _$AppearanceSettingsState {
  const factory AppearanceSettingsState({
    required FlowyTheme theme,
    required Locale locale,
  }) = _AppearanceSettingsState;
}
