// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class AppFlowyEditorLocalizations {
  AppFlowyEditorLocalizations();

  static AppFlowyEditorLocalizations? _current;

  static AppFlowyEditorLocalizations get current {
    assert(_current != null,
        'No instance of AppFlowyEditorLocalizations was loaded. Try to initialize the AppFlowyEditorLocalizations delegate before accessing AppFlowyEditorLocalizations.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<AppFlowyEditorLocalizations> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = AppFlowyEditorLocalizations();
      AppFlowyEditorLocalizations._current = instance;

      return instance;
    });
  }

  static AppFlowyEditorLocalizations of(BuildContext context) {
    final instance = AppFlowyEditorLocalizations.maybeOf(context);
    assert(instance != null,
        'No instance of AppFlowyEditorLocalizations present in the widget tree. Did you add AppFlowyEditorLocalizations.delegate in localizationsDelegates?');
    return instance!;
  }

  static AppFlowyEditorLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppFlowyEditorLocalizations>(
        context, AppFlowyEditorLocalizations);
  }

  /// `Bold`
  String get bold {
    return Intl.message(
      'Bold',
      name: 'bold',
      desc: '',
      args: [],
    );
  }

  /// `Bulleted List`
  String get bulletedList {
    return Intl.message(
      'Bulleted List',
      name: 'bulletedList',
      desc: '',
      args: [],
    );
  }

  /// `Checkbox`
  String get checkbox {
    return Intl.message(
      'Checkbox',
      name: 'checkbox',
      desc: '',
      args: [],
    );
  }

  /// `Embed Code`
  String get embedCode {
    return Intl.message(
      'Embed Code',
      name: 'embedCode',
      desc: '',
      args: [],
    );
  }

  /// `H1`
  String get heading1 {
    return Intl.message(
      'H1',
      name: 'heading1',
      desc: '',
      args: [],
    );
  }

  /// `H2`
  String get heading2 {
    return Intl.message(
      'H2',
      name: 'heading2',
      desc: '',
      args: [],
    );
  }

  /// `H3`
  String get heading3 {
    return Intl.message(
      'H3',
      name: 'heading3',
      desc: '',
      args: [],
    );
  }

  /// `Highlight`
  String get highlight {
    return Intl.message(
      'Highlight',
      name: 'highlight',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get color {
    return Intl.message(
      'Color',
      name: 'color',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get image {
    return Intl.message(
      'Image',
      name: 'image',
      desc: '',
      args: [],
    );
  }

  /// `Italic`
  String get italic {
    return Intl.message(
      'Italic',
      name: 'italic',
      desc: '',
      args: [],
    );
  }

  /// `Link`
  String get link {
    return Intl.message(
      'Link',
      name: 'link',
      desc: '',
      args: [],
    );
  }

  /// `Numbered List`
  String get numberedList {
    return Intl.message(
      'Numbered List',
      name: 'numberedList',
      desc: '',
      args: [],
    );
  }

  /// `Quote`
  String get quote {
    return Intl.message(
      'Quote',
      name: 'quote',
      desc: '',
      args: [],
    );
  }

  /// `Strikethrough`
  String get strikethrough {
    return Intl.message(
      'Strikethrough',
      name: 'strikethrough',
      desc: '',
      args: [],
    );
  }

  /// `Text`
  String get text {
    return Intl.message(
      'Text',
      name: 'text',
      desc: '',
      args: [],
    );
  }

  /// `Underline`
  String get underline {
    return Intl.message(
      'Underline',
      name: 'underline',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get fontColorDefault {
    return Intl.message(
      'Default',
      name: 'fontColorDefault',
      desc: '',
      args: [],
    );
  }

  /// `Gray`
  String get fontColorGray {
    return Intl.message(
      'Gray',
      name: 'fontColorGray',
      desc: '',
      args: [],
    );
  }

  /// `Brown`
  String get fontColorBrown {
    return Intl.message(
      'Brown',
      name: 'fontColorBrown',
      desc: '',
      args: [],
    );
  }

  /// `Orange`
  String get fontColorOrange {
    return Intl.message(
      'Orange',
      name: 'fontColorOrange',
      desc: '',
      args: [],
    );
  }

  /// `Yellow`
  String get fontColorYellow {
    return Intl.message(
      'Yellow',
      name: 'fontColorYellow',
      desc: '',
      args: [],
    );
  }

  /// `Green`
  String get fontColorGreen {
    return Intl.message(
      'Green',
      name: 'fontColorGreen',
      desc: '',
      args: [],
    );
  }

  /// `Blue`
  String get fontColorBlue {
    return Intl.message(
      'Blue',
      name: 'fontColorBlue',
      desc: '',
      args: [],
    );
  }

  /// `Purple`
  String get fontColorPurple {
    return Intl.message(
      'Purple',
      name: 'fontColorPurple',
      desc: '',
      args: [],
    );
  }

  /// `Pink`
  String get fontColorPink {
    return Intl.message(
      'Pink',
      name: 'fontColorPink',
      desc: '',
      args: [],
    );
  }

  /// `Red`
  String get fontColorRed {
    return Intl.message(
      'Red',
      name: 'fontColorRed',
      desc: '',
      args: [],
    );
  }

  /// `Default background`
  String get backgroundColorDefault {
    return Intl.message(
      'Default background',
      name: 'backgroundColorDefault',
      desc: '',
      args: [],
    );
  }

  /// `Gray background`
  String get backgroundColorGray {
    return Intl.message(
      'Gray background',
      name: 'backgroundColorGray',
      desc: '',
      args: [],
    );
  }

  /// `Brown background`
  String get backgroundColorBrown {
    return Intl.message(
      'Brown background',
      name: 'backgroundColorBrown',
      desc: '',
      args: [],
    );
  }

  /// `Orange background`
  String get backgroundColorOrange {
    return Intl.message(
      'Orange background',
      name: 'backgroundColorOrange',
      desc: '',
      args: [],
    );
  }

  /// `Yellow background`
  String get backgroundColorYellow {
    return Intl.message(
      'Yellow background',
      name: 'backgroundColorYellow',
      desc: '',
      args: [],
    );
  }

  /// `Green background`
  String get backgroundColorGreen {
    return Intl.message(
      'Green background',
      name: 'backgroundColorGreen',
      desc: '',
      args: [],
    );
  }

  /// `Blue background`
  String get backgroundColorBlue {
    return Intl.message(
      'Blue background',
      name: 'backgroundColorBlue',
      desc: '',
      args: [],
    );
  }

  /// `Purple background`
  String get backgroundColorPurple {
    return Intl.message(
      'Purple background',
      name: 'backgroundColorPurple',
      desc: '',
      args: [],
    );
  }

  /// `Pink background`
  String get backgroundColorPink {
    return Intl.message(
      'Pink background',
      name: 'backgroundColorPink',
      desc: '',
      args: [],
    );
  }

  /// `Red background`
  String get backgroundColorRed {
    return Intl.message(
      'Red background',
      name: 'backgroundColorRed',
      desc: '',
      args: [],
    );
  }

  /// `Tint 1`
  String get tint1 {
    return Intl.message(
      'Tint 1',
      name: 'tint1',
      desc: '',
      args: [],
    );
  }

  /// `Tint 2`
  String get tint2 {
    return Intl.message(
      'Tint 2',
      name: 'tint2',
      desc: '',
      args: [],
    );
  }

  /// `Tint 3`
  String get tint3 {
    return Intl.message(
      'Tint 3',
      name: 'tint3',
      desc: '',
      args: [],
    );
  }

  /// `Tint 4`
  String get tint4 {
    return Intl.message(
      'Tint 4',
      name: 'tint4',
      desc: '',
      args: [],
    );
  }

  /// `Tint 5`
  String get tint5 {
    return Intl.message(
      'Tint 5',
      name: 'tint5',
      desc: '',
      args: [],
    );
  }

  /// `Tint 6`
  String get tint6 {
    return Intl.message(
      'Tint 6',
      name: 'tint6',
      desc: '',
      args: [],
    );
  }

  /// `Tint 7`
  String get tint7 {
    return Intl.message(
      'Tint 7',
      name: 'tint7',
      desc: '',
      args: [],
    );
  }

  /// `Tint 8`
  String get tint8 {
    return Intl.message(
      'Tint 8',
      name: 'tint8',
      desc: '',
      args: [],
    );
  }

  /// `Tint 9`
  String get tint9 {
    return Intl.message(
      'Tint 9',
      name: 'tint9',
      desc: '',
      args: [],
    );
  }

  /// `Purple`
  String get lightLightTint1 {
    return Intl.message(
      'Purple',
      name: 'lightLightTint1',
      desc: '',
      args: [],
    );
  }

  /// `Pink`
  String get lightLightTint2 {
    return Intl.message(
      'Pink',
      name: 'lightLightTint2',
      desc: '',
      args: [],
    );
  }

  /// `Light Pink`
  String get lightLightTint3 {
    return Intl.message(
      'Light Pink',
      name: 'lightLightTint3',
      desc: '',
      args: [],
    );
  }

  /// `Orange`
  String get lightLightTint4 {
    return Intl.message(
      'Orange',
      name: 'lightLightTint4',
      desc: '',
      args: [],
    );
  }

  /// `Yellow`
  String get lightLightTint5 {
    return Intl.message(
      'Yellow',
      name: 'lightLightTint5',
      desc: '',
      args: [],
    );
  }

  /// `Lime`
  String get lightLightTint6 {
    return Intl.message(
      'Lime',
      name: 'lightLightTint6',
      desc: '',
      args: [],
    );
  }

  /// `Green`
  String get lightLightTint7 {
    return Intl.message(
      'Green',
      name: 'lightLightTint7',
      desc: '',
      args: [],
    );
  }

  /// `Aqua`
  String get lightLightTint8 {
    return Intl.message(
      'Aqua',
      name: 'lightLightTint8',
      desc: '',
      args: [],
    );
  }

  /// `Blue`
  String get lightLightTint9 {
    return Intl.message(
      'Blue',
      name: 'lightLightTint9',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate
    extends LocalizationsDelegate<AppFlowyEditorLocalizations> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'bn', countryCode: 'BN'),
      Locale.fromSubtags(languageCode: 'ca'),
      Locale.fromSubtags(languageCode: 'cs', countryCode: 'CZ'),
      Locale.fromSubtags(languageCode: 'de', countryCode: 'DE'),
      Locale.fromSubtags(languageCode: 'es', countryCode: 'VE'),
      Locale.fromSubtags(languageCode: 'fr', countryCode: 'CA'),
      Locale.fromSubtags(languageCode: 'fr', countryCode: 'FR'),
      Locale.fromSubtags(languageCode: 'hi', countryCode: 'IN'),
      Locale.fromSubtags(languageCode: 'hu', countryCode: 'HU'),
      Locale.fromSubtags(languageCode: 'id', countryCode: 'ID'),
      Locale.fromSubtags(languageCode: 'it', countryCode: 'IT'),
      Locale.fromSubtags(languageCode: 'ja', countryCode: 'JP'),
      Locale.fromSubtags(languageCode: 'ml', countryCode: 'IN'),
      Locale.fromSubtags(languageCode: 'nl', countryCode: 'NL'),
      Locale.fromSubtags(languageCode: 'pl', countryCode: 'PL'),
      Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      Locale.fromSubtags(languageCode: 'pt', countryCode: 'PT'),
      Locale.fromSubtags(languageCode: 'ru', countryCode: 'RU'),
      Locale.fromSubtags(languageCode: 'tr', countryCode: 'TR'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<AppFlowyEditorLocalizations> load(Locale locale) =>
      AppFlowyEditorLocalizations.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
