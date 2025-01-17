import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'emoji_picker.dart';
import 'models/emoji_category_models.dart';

part 'emji_picker_config.freezed.dart';

@freezed
class EmojiPickerConfig with _$EmojiPickerConfig {
  // private empty constructor is used to make method work in freezed
  // https://pub.dev/packages/freezed#adding-getters-and-methods-to-our-models
  const EmojiPickerConfig._();
  const factory EmojiPickerConfig({
    @Default(7) int emojiNumberPerRow,
    // The maximum size(width and height) of emoji
    // It also depaneds on the screen size and emojiNumberPerRow
    @Default(32) double emojiSizeMax,
    // Vertical spacing between emojis
    @Default(0) double verticalSpacing,
    // Horizontal spacing between emojis
    @Default(0) double horizontalSpacing,
    // The initial [EmojiCategory] that will be selected
    @Default(EmojiCategory.RECENT) EmojiCategory initCategory,
    // The background color of the Widget
    @Default(Color(0xFFEBEFF2)) Color? bgColor,
    // The color of the category icons
    @Default(Colors.grey) Color? categoryIconColor,
    // The color of the category icon when selected
    @Default(Colors.blue) Color? selectedCategoryIconColor,
    // The color of the category indicator
    @Default(Colors.blue) Color? selectedCategoryIconBackgroundColor,
    // The color of the loading indicator during initialization
    @Default(Colors.blue) Color? progressIndicatorColor,
    // The color of the backspace icon button
    @Default(Colors.blue) Color? backspaceColor,
    // Show extra tab with recently used emoji
    @Default(true) bool showRecentsTab,
    // Limit of recently used emoji that will be saved
    @Default(28) int recentsLimit,
    @Default('Search emoji') String searchHintText,
    TextStyle? serachHintTextStyle,
    InputBorder? serachBarEnableBorder,
    InputBorder? serachBarFocusedBorder,
    // The text to be displayed if no recent emojis to display
    @Default('No recent emoji') String noRecentsText,
    TextStyle? noRecentsStyle,
    // The text to be displayed if no emoji found
    @Default('No emoji found') String noEmojiFoundText,
    Color? scrollBarHandleColor,
    // Duration of tab indicator to animate to next category
    @Default(kTabScrollDuration) Duration tabIndicatorAnimDuration,
    // Determines the icon to display for each [EmojiCategory]
    @Default(EmojiCategoryIcons()) EmojiCategoryIcons emojiCategoryIcons,
    // Change between Material and Cupertino button style
    @Default(ButtonMode.MATERIAL) ButtonMode buttonMode,
  }) = _EmojiPickerConfig;

  /// Get Emoji size based on properties and screen width
  double getEmojiSize(double width) {
    final maxSize = width / emojiNumberPerRow;
    return min(maxSize, emojiSizeMax);
  }

  /// Returns the icon for the category
  IconData getIconForCategory(EmojiCategory category) {
    switch (category) {
      case EmojiCategory.RECENT:
        return emojiCategoryIcons.recentIcon;
      case EmojiCategory.SMILEYS:
        return emojiCategoryIcons.smileyIcon;
      case EmojiCategory.ANIMALS:
        return emojiCategoryIcons.animalIcon;
      case EmojiCategory.FOODS:
        return emojiCategoryIcons.foodIcon;
      case EmojiCategory.TRAVEL:
        return emojiCategoryIcons.travelIcon;
      case EmojiCategory.ACTIVITIES:
        return emojiCategoryIcons.activityIcon;
      case EmojiCategory.OBJECTS:
        return emojiCategoryIcons.objectIcon;
      case EmojiCategory.SYMBOLS:
        return emojiCategoryIcons.symbolIcon;
      case EmojiCategory.FLAGS:
        return emojiCategoryIcons.flagIcon;
      case EmojiCategory.SEARCH:
        return emojiCategoryIcons.searchIcon;
    }
  }
}
