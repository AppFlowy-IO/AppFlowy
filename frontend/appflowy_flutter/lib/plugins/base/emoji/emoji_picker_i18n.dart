import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

class FlowyEmojiPickerI18n extends EmojiPickerI18n {
  @override
  String get activity => LocaleKeys.emoji_categories_activities.tr();

  @override
  String get flags => LocaleKeys.emoji_categories_flags.tr();

  @override
  String get foods => LocaleKeys.emoji_categories_food.tr();

  @override
  String get frequent => LocaleKeys.emoji_categories_frequentlyUsed.tr();

  @override
  String get nature => LocaleKeys.emoji_categories_nature.tr();

  @override
  String get objects => LocaleKeys.emoji_categories_objects.tr();

  @override
  String get people => LocaleKeys.emoji_categories_smileys.tr();

  @override
  String get places => LocaleKeys.emoji_categories_places.tr();

  @override
  String get search => LocaleKeys.emoji_search.tr();

  @override
  String get symbols => LocaleKeys.emoji_categories_symbols.tr();

  @override
  String get searchHintText => LocaleKeys.emoji_search.tr();

  @override
  String get searchNoResult => LocaleKeys.emoji_noEmojiFound.tr();
}
