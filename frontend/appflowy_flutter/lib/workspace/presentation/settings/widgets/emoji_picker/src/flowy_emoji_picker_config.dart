import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

EmojiPickerConfig buildFlowyEmojiPickerConfig(BuildContext context) {
  final style = Theme.of(context);
  return EmojiPickerConfig(
    bgColor: style.cardColor,
    categoryIconColor: style.iconTheme.color,
    selectedCategoryIconColor: style.colorScheme.onSurface,
    selectedCategoryIconBackgroundColor: style.colorScheme.primary,
    progressIndicatorColor: style.colorScheme.primary,
    backspaceColor: style.colorScheme.primary,
    searchHintText: LocaleKeys.emoji_search.tr(),
    serachHintTextStyle: style.textTheme.bodyMedium?.copyWith(
      color: style.hintColor,
    ),
    serachBarEnableBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: style.dividerColor),
    ),
    serachBarFocusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: style.colorScheme.primary,
      ),
    ),
    noRecentsText: LocaleKeys.emoji_noRecent.tr(),
    noRecentsStyle: style.textTheme.bodyMedium,
    noEmojiFoundText: LocaleKeys.emoji_noEmojiFound.tr(),
    scrollBarHandleColor: style.colorScheme.onSurface,
  );
}
