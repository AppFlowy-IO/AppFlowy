import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/emji_picker_config.dart';
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
    searchHintText: 'Search emoji localations',
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
    noRecentsText: 'No Recents localations',
    noRecentsStyle: style.textTheme.bodyMedium,
    noEmojiFoundText: 'No emoji found localations',
    scrollBarHandleColor: style.colorScheme.primary,
  );
}
