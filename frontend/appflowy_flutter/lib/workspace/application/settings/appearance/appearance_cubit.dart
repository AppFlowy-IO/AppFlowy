import 'dart:async';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show AppFlowyEditorLocalizations;
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
            appearanceSettings.enableRtlToolbarItems,
            appearanceSettings.locale,
            appearanceSettings.isMenuCollapsed,
            appearanceSettings.menuOffset,
            dateTimeSettings.dateFormat,
            dateTimeSettings.timeFormat,
            dateTimeSettings.timezoneId,
            appearanceSettings.documentSetting.cursorColor.isEmpty
                ? null
                : Color(
                    int.parse(appearanceSettings.documentSetting.cursorColor),
                  ),
            appearanceSettings.documentSetting.selectionColor.isEmpty
                ? null
                : Color(
                    int.parse(
                      appearanceSettings.documentSetting.selectionColor,
                    ),
                  ),
            1.0,
          ),
        ) {
    readTextScaleFactor();
  }

  final AppearanceSettingsPB _appearanceSettings;
  final DateTimeSettingsPB _dateTimeSettings;

  Future<void> setTextScaleFactor(double textScaleFactor) async {
    // only saved in local storage, this value is not synced across devices
    await getIt<KeyValueStorage>().set(
      KVKeys.textScaleFactor,
      textScaleFactor.toString(),
    );

    // don't allow the text scale factor to be greater than 1.0, it will cause
    // ui issues
    emit(state.copyWith(textScaleFactor: textScaleFactor.clamp(0.7, 1.0)));
  }

  Future<void> readTextScaleFactor() async {
    final textScaleFactor = await getIt<KeyValueStorage>().getWithFormat(
          KVKeys.textScaleFactor,
          (value) => double.parse(value),
        ) ??
        1.0;
    emit(state.copyWith(textScaleFactor: textScaleFactor.clamp(0.7, 1.0)));
  }

  /// Update selected theme in the user's settings and emit an updated state
  /// with the AppTheme named [themeName].
  Future<void> setTheme(String themeName) async {
    _appearanceSettings.theme = themeName;
    unawaited(_saveAppearanceSettings());
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

  void setEnableRTLToolbarItems(bool value) {
    _appearanceSettings.enableRtlToolbarItems = value;
    _saveAppearanceSettings();
    emit(state.copyWith(enableRtlToolbarItems: value));
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

  /// Update document cursor color in the apperance settings and emit an updated state.
  void setDocumentCursorColor(Color color) {
    _appearanceSettings.documentSetting.cursorColor = color.toHexString();
    _saveAppearanceSettings();
    emit(state.copyWith(documentCursorColor: color));
  }

  /// Reset document cursor color in the apperance settings
  void resetDocumentCursorColor() {
    _appearanceSettings.documentSetting.cursorColor = '';
    _saveAppearanceSettings();
    emit(state.copyWith(documentCursorColor: null));
  }

  /// Update document selection color in the apperance settings and emit an updated state.
  void setDocumentSelectionColor(Color color) {
    _appearanceSettings.documentSetting.selectionColor = color.toHexString();
    _saveAppearanceSettings();
    emit(state.copyWith(documentSelectionColor: color));
  }

  /// Reset document selection color in the apperance settings
  void resetDocumentSelectionColor() {
    _appearanceSettings.documentSetting.selectionColor = '';
    _saveAppearanceSettings();
    emit(state.copyWith(documentSelectionColor: null));
  }

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

    // Sync the app's locale with the editor (initialization and update)
    AppFlowyEditorLocalizations.load(newLocale);

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
    final result = await UserSettingsBackendService()
        .setDateTimeSettings(_dateTimeSettings);
    result.fold(
      (_) => null,
      (error) => Log.error(error),
    );
  }

  Future<void> _saveAppearanceSettings() async {
    final result = await UserSettingsBackendService()
        .setAppearanceSetting(_appearanceSettings);
    result.fold(
      (l) => null,
      (error) => Log.error(error),
    );
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
    required bool enableRtlToolbarItems,
    required Locale locale,
    required bool isMenuCollapsed,
    required double menuOffset,
    required UserDateFormatPB dateFormat,
    required UserTimeFormatPB timeFormat,
    required String timezoneId,
    required Color? documentCursorColor,
    required Color? documentSelectionColor,
    required double textScaleFactor,
  }) = _AppearanceSettingsState;

  factory AppearanceSettingsState.initial(
    AppTheme appTheme,
    ThemeModePB themeModePB,
    String font,
    String monospaceFont,
    LayoutDirectionPB layoutDirectionPB,
    TextDirectionPB? textDirectionPB,
    bool enableRtlToolbarItems,
    LocaleSettingsPB localePB,
    bool isMenuCollapsed,
    double menuOffset,
    UserDateFormatPB dateFormat,
    UserTimeFormatPB timeFormat,
    String timezoneId,
    Color? documentCursorColor,
    Color? documentSelectionColor,
    double textScaleFactor,
  ) {
    return AppearanceSettingsState(
      appTheme: appTheme,
      font: font,
      monospaceFont: monospaceFont,
      layoutDirection: LayoutDirection.fromLayoutDirectionPB(layoutDirectionPB),
      textDirection: AppFlowyTextDirection.fromTextDirectionPB(textDirectionPB),
      enableRtlToolbarItems: enableRtlToolbarItems,
      themeMode: _themeModeFromPB(themeModePB),
      locale: Locale(localePB.languageCode, localePB.countryCode),
      isMenuCollapsed: isMenuCollapsed,
      menuOffset: menuOffset,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      timezoneId: timezoneId,
      documentCursorColor: documentCursorColor,
      documentSelectionColor: documentSelectionColor,
      textScaleFactor: textScaleFactor,
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
