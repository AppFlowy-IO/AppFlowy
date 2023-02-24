// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that looks up messages for specific locales by
// delegating to the appropriate library.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:implementation_imports, file_names, unnecessary_new
// ignore_for_file:unnecessary_brace_in_string_interps, directives_ordering
// ignore_for_file:argument_type_not_assignable, invalid_assignment
// ignore_for_file:prefer_single_quotes, prefer_generic_function_type_aliases
// ignore_for_file:comment_references

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

import 'messages_bn_BN.dart' as messages_bn_bn;
import 'messages_ca.dart' as messages_ca;
import 'messages_cs-CZ.dart' as messages_cs_cz;
import 'messages_de-DE.dart' as messages_de_de;
import 'messages_en.dart' as messages_en;
import 'messages_es-VE.dart' as messages_es_ve;
import 'messages_fr-CA.dart' as messages_fr_ca;
import 'messages_fr-FR.dart' as messages_fr_fr;
import 'messages_hi-IN.dart' as messages_hi_in;
import 'messages_hu-HU.dart' as messages_hu_hu;
import 'messages_id-ID.dart' as messages_id_id;
import 'messages_it-IT.dart' as messages_it_it;
import 'messages_ja-JP.dart' as messages_ja_jp;
import 'messages_ml_IN.dart' as messages_ml_in;
import 'messages_nl-NL.dart' as messages_nl_nl;
import 'messages_pl-PL.dart' as messages_pl_pl;
import 'messages_pt-BR.dart' as messages_pt_br;
import 'messages_pt-PT.dart' as messages_pt_pt;
import 'messages_ru-RU.dart' as messages_ru_ru;
import 'messages_tr-TR.dart' as messages_tr_tr;
import 'messages_zh-CN.dart' as messages_zh_cn;
import 'messages_zh-TW.dart' as messages_zh_tw;

typedef Future<dynamic> LibraryLoader();
Map<String, LibraryLoader> _deferredLibraries = {
  'bn_BN': () => new Future.value(null),
  'ca': () => new Future.value(null),
  'cs_CZ': () => new Future.value(null),
  'de_DE': () => new Future.value(null),
  'en': () => new Future.value(null),
  'es_VE': () => new Future.value(null),
  'fr_CA': () => new Future.value(null),
  'fr_FR': () => new Future.value(null),
  'hi_IN': () => new Future.value(null),
  'hu_HU': () => new Future.value(null),
  'id_ID': () => new Future.value(null),
  'it_IT': () => new Future.value(null),
  'ja_JP': () => new Future.value(null),
  'ml_IN': () => new Future.value(null),
  'nl_NL': () => new Future.value(null),
  'pl_PL': () => new Future.value(null),
  'pt_BR': () => new Future.value(null),
  'pt_PT': () => new Future.value(null),
  'ru_RU': () => new Future.value(null),
  'tr_TR': () => new Future.value(null),
  'zh_CN': () => new Future.value(null),
  'zh_TW': () => new Future.value(null),
};

MessageLookupByLibrary? _findExact(String localeName) {
  switch (localeName) {
    case 'bn_BN':
      return messages_bn_bn.messages;
    case 'ca':
      return messages_ca.messages;
    case 'cs_CZ':
      return messages_cs_cz.messages;
    case 'de_DE':
      return messages_de_de.messages;
    case 'en':
      return messages_en.messages;
    case 'es_VE':
      return messages_es_ve.messages;
    case 'fr_CA':
      return messages_fr_ca.messages;
    case 'fr_FR':
      return messages_fr_fr.messages;
    case 'hi_IN':
      return messages_hi_in.messages;
    case 'hu_HU':
      return messages_hu_hu.messages;
    case 'id_ID':
      return messages_id_id.messages;
    case 'it_IT':
      return messages_it_it.messages;
    case 'ja_JP':
      return messages_ja_jp.messages;
    case 'ml_IN':
      return messages_ml_in.messages;
    case 'nl_NL':
      return messages_nl_nl.messages;
    case 'pl_PL':
      return messages_pl_pl.messages;
    case 'pt_BR':
      return messages_pt_br.messages;
    case 'pt_PT':
      return messages_pt_pt.messages;
    case 'ru_RU':
      return messages_ru_ru.messages;
    case 'tr_TR':
      return messages_tr_tr.messages;
    case 'zh_CN':
      return messages_zh_cn.messages;
    case 'zh_TW':
      return messages_zh_tw.messages;
    default:
      return null;
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName) async {
  var availableLocale = Intl.verifiedLocale(
      localeName, (locale) => _deferredLibraries[locale] != null,
      onFailure: (_) => null);
  if (availableLocale == null) {
    return new Future.value(false);
  }
  var lib = _deferredLibraries[availableLocale];
  await (lib == null ? new Future.value(false) : lib());
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, _findGeneratedMessagesFor);
  return new Future.value(true);
}

bool _messagesExistFor(String locale) {
  try {
    return _findExact(locale) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary? _findGeneratedMessagesFor(String locale) {
  var actualLocale =
      Intl.verifiedLocale(locale, _messagesExistFor, onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
