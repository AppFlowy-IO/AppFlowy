import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models/category_models.dart';
import 'emoji_picker.dart';

part 'emji_picker_config.freezed.dart';

@freezed
class EmojiPickerConfig with _$EmojiPickerConfig {
  const factory EmojiPickerConfig({
    @Default(7) int emojiNumberPerRow,
    // The maximum size(width and height) of emoji
    // It also depaneds on the screen size and emojiNumberPerRow
    @Default(32) double emojiSizeMax,
    // Vertical spacing between emojis
    @Default(0) double verticalSpacing,
    // Horizontal spacing between emojis
    @Default(0) double horizontalSpacing,
    // The initial [Category] that will be selected
    @Default(Category.RECENT) Category initCategory,
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
    // Determines the icon to display for each [Category]
    @Default(CategoryIcons()) CategoryIcons categoryIcons,
    // Change between Material and Cupertino button style
    @Default(ButtonMode.MATERIAL) ButtonMode buttonMode,
  }) = _EmojiPickerConfig;

  /// Get Emoji size based on properties and screen width
  double getEmojiSize(double width) {
    final maxSize = width / emojiNumberPerRow;
    return min(maxSize, emojiSizeMax);
  }

  /// Returns the icon for the category
  IconData getIconForCategory(Category category) {
    switch (category) {
      case Category.RECENT:
        return categoryIcons.recentIcon;
      case Category.SMILEYS:
        return categoryIcons.smileyIcon;
      case Category.ANIMALS:
        return categoryIcons.animalIcon;
      case Category.FOODS:
        return categoryIcons.foodIcon;
      case Category.TRAVEL:
        return categoryIcons.travelIcon;
      case Category.ACTIVITIES:
        return categoryIcons.activityIcon;
      case Category.OBJECTS:
        return categoryIcons.objectIcon;
      case Category.SYMBOLS:
        return categoryIcons.symbolIcon;
      case Category.FLAGS:
        return categoryIcons.flagIcon;
      case Category.SEARCH:
        return categoryIcons.searchIcon;
      default:
        throw Exception('Unsupported Category');
    }
  }
}
