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

class FlowyInfraLocalizations {
  FlowyInfraLocalizations();

  static FlowyInfraLocalizations? _current;

  static FlowyInfraLocalizations get current {
    assert(_current != null,
        'No instance of FlowyInfraLocalizations was loaded. Try to initialize the FlowyInfraLocalizations delegate before accessing FlowyInfraLocalizations.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<FlowyInfraLocalizations> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = FlowyInfraLocalizations();
      FlowyInfraLocalizations._current = instance;

      return instance;
    });
  }

  static FlowyInfraLocalizations of(BuildContext context) {
    final instance = FlowyInfraLocalizations.maybeOf(context);
    assert(instance != null,
        'No instance of FlowyInfraLocalizations present in the widget tree. Did you add FlowyInfraLocalizations.delegate in localizationsDelegates?');
    return instance!;
  }

  static FlowyInfraLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<FlowyInfraLocalizations>(
        context, FlowyInfraLocalizations);
  }

  /// `Purple`
  String get purpleTint {
    return Intl.message(
      'Purple',
      name: 'purpleTint',
      desc: '',
      args: [],
    );
  }

  /// `Pink`
  String get pinkTint {
    return Intl.message(
      'Pink',
      name: 'pinkTint',
      desc: '',
      args: [],
    );
  }

  /// `Light Pink`
  String get lightPinkTint {
    return Intl.message(
      'Light Pink',
      name: 'lightPinkTint',
      desc: '',
      args: [],
    );
  }

  /// `Orange`
  String get orangeTint {
    return Intl.message(
      'Orange',
      name: 'orangeTint',
      desc: '',
      args: [],
    );
  }

  /// `Yellow`
  String get yellowTint {
    return Intl.message(
      'Yellow',
      name: 'yellowTint',
      desc: '',
      args: [],
    );
  }

  /// `Lime`
  String get limeTint {
    return Intl.message(
      'Lime',
      name: 'limeTint',
      desc: '',
      args: [],
    );
  }

  /// `Green`
  String get greenTint {
    return Intl.message(
      'Green',
      name: 'greenTint',
      desc: '',
      args: [],
    );
  }

  /// `Aqua`
  String get aquaTint {
    return Intl.message(
      'Aqua',
      name: 'aquaTint',
      desc: '',
      args: [],
    );
  }

  /// `Blue`
  String get blueTint {
    return Intl.message(
      'Blue',
      name: 'blueTint',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate
    extends LocalizationsDelegate<FlowyInfraLocalizations> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<FlowyInfraLocalizations> load(Locale locale) =>
      FlowyInfraLocalizations.load(locale);
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
