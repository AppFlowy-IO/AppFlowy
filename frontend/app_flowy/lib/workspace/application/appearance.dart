import 'dart:async';

import 'package:app_flowy/user/application/user_settings_service.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_setting.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'appearance.freezed.dart';

const _white = Color(0xFFFFFFFF);

/// [AppearanceSettingsCubit] is used to modify the appearance of AppFlowy.
/// It includes the [AppTheme], [ThemeMode], [TextStyles] and [Locale].
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

  /// Update selected theme in the user's settings and emit an updated state
  /// with the AppTheme named [themeName].
  void setTheme(String themeName) {
    _setting.theme = themeName;
    _saveAppearanceSettings();
    final appTheme = AppTheme.fromName(themeName: themeName);
    final textTheme =
        TextStyles(font: _setting.font, monospaceFont: _setting.monospaceFont);
    emit(state.copyWith(
      lightTheme:
          _getThemeData(appTheme, Brightness.light, textTheme, state.locale),
      darkTheme:
          _getThemeData(appTheme, Brightness.dark, textTheme, state.locale),
    ));
  }

  /// Update the theme mode in the user's settings and emit an updated state.
  void setThemeMode(ThemeMode themeMode) {
    _setting.themeMode = _themeModeToPB(themeMode);
    _saveAppearanceSettings();
    emit(state.copyWith(themeMode: themeMode));
  }

  /// Updates the current locale and notify the listeners the locale was
  /// changed. Fallback to [en] locale if [newLocale] is not supported.
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

ThemeData _getThemeData(AppTheme appTheme, Brightness brightness,
    TextStyles textTheme, Locale locale) {
  // Poppins and SF Mono are not well supported in some languages, so use the
  // built-in font for the following languages.
  final useBuiltInFontLanguages = [
    const Locale('zh', 'CN'),
    const Locale('zh', 'TW'),
  ];
  if (useBuiltInFontLanguages.contains(locale)) {
    textTheme = TextStyles(font: '', monospaceFont: '');
  }

  final theme =
      brightness == Brightness.light ? appTheme.lightTheme : appTheme.darkTheme;

  return ThemeData(
    brightness: brightness,
    textTheme: textTheme.getTextTheme(fontColor: theme.shader1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: theme.main2,
      selectionHandleColor: theme.main2,
    ),
    primaryIconTheme: IconThemeData(color: theme.hover),
    iconTheme: IconThemeData(color: theme.shader1),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(Colors.transparent),
    ),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    canvasColor: theme.shader6,
    dividerColor: theme.shader6,
    hintColor: theme.shader3,
    disabledColor: theme.shader4,
    highlightColor: theme.main1,
    indicatorColor: theme.main1,
    toggleableActiveColor: theme.main1,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: theme.main1,
      onPrimary: _white,
      primaryContainer: theme.main2,
      onPrimaryContainer: _white,
      secondary: theme.hover,
      onSecondary: theme.shader1,
      secondaryContainer: theme.selector,
      onSecondaryContainer: theme.shader1,
      background: theme.surface,
      onBackground: theme.shader1,
      surface: theme.surface,
      onSurface: theme.shader1,
      onError: theme.shader7,
      error: theme.red,
      outline: theme.shader4,
      surfaceVariant: theme.bg1,
      shadow: theme.shadow,
    ),
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
        greyHover: theme.bg2,
        greySelect: theme.bg3,
        lightGreyHover: theme.shader6,
        toggleOffFill: theme.shader5,
        code: textTheme.getMonospaceFontSyle(fontColor: theme.shader1),
        callout: textTheme.getFontStyle(
          fontSize: FontSizes.s11,
          fontColor: theme.shader3,
        ),
        caption: textTheme.getFontStyle(
          fontSize: FontSizes.s11,
          fontWeight: FontWeight.w400,
          fontColor: theme.shader3,
        ),
      )
    ],
  );
}

@freezed
class AppearanceSettingsState with _$AppearanceSettingsState {
  const factory AppearanceSettingsState({
    required ThemeData lightTheme,
    required ThemeData darkTheme,
    required ThemeMode themeMode,
    required Locale locale,
  }) = _AppearanceSettingsState;

  factory AppearanceSettingsState.initial(
    String themeName,
    ThemeModePB themeModePB,
    String font,
    String monospaceFont,
    LocaleSettingsPB localePB,
  ) {
    final textTheme = TextStyles(font: font, monospaceFont: monospaceFont);
    final appTheme = AppTheme.fromName(themeName: themeName);
    final locale = Locale(localePB.languageCode, localePB.countryCode);

    return AppearanceSettingsState(
      lightTheme: _getThemeData(appTheme, Brightness.light, textTheme, locale),
      darkTheme: _getThemeData(appTheme, Brightness.dark, textTheme, locale),
      themeMode: _themeModeFromPB(themeModePB),
      locale: locale,
    );
  }
}
