import 'dart:math';

import 'package:flutter/material.dart';

import 'models/category_models.dart';
import 'emoji_picker.dart';

/// Config for customizations
class EmojiPickerConfig {
  /// Constructor
  const EmojiPickerConfig({
    this.emojiNumberPerRow = 7,
    this.emojiSizeMax = 32.0,
    this.verticalSpacing = 0,
    this.horizontalSpacing = 0,
    this.initCategory = Category.RECENT,
    this.bgColor = const Color(0xFFEBEFF2),
    this.categoryIconColor = Colors.grey,
    this.selectedCategoryIconColor = Colors.blue,
    this.selectedCategoryIconBackgroundColor = Colors.blue,
    this.progressIndicatorColor = Colors.blue,
    this.backspaceColor = Colors.blue,
    this.showRecentsTab = true,
    this.recentsLimit = 28,
    this.searchHintText = 'Search emoji',
    this.serachHintTextStyle,
    this.serachBarEnableBorder,
    this.serachBarFocusedBorder,
    this.noRecentsText = 'No Recents',
    this.noRecentsStyle,
    this.noEmojiFoundText = 'No emoji found',
    this.scrollBarHandleColor,
    this.tabIndicatorAnimDuration = kTabScrollDuration,
    this.categoryIcons = const CategoryIcons(),
    this.buttonMode = ButtonMode.MATERIAL,
  });

  /// Number of emojis per row
  final int emojiNumberPerRow;

  /// Width and height the emoji will be maximal displayed
  /// Can be smaller due to screen size and amount of columns
  final double emojiSizeMax;

  /// Vertical spacing between emojis
  final double verticalSpacing;

  /// Horizontal spacing between emojis
  final double horizontalSpacing;

  /// The initial [Category] that will be selected
  /// This [Category] will have its button in the bottombar darkened
  final Category initCategory;

  /// The background color of the Widget
  final Color? bgColor;

  /// The color of the category icons
  final Color? categoryIconColor;

  /// The color of the category icon when selected
  final Color? selectedCategoryIconColor;

  /// The color of the category indicator
  final Color? selectedCategoryIconBackgroundColor;

  /// The color of the loading indicator during initialization
  final Color? progressIndicatorColor;

  /// The color of the backspace icon button
  final Color? backspaceColor;

  /// Show extra tab with recently used emoji
  final bool showRecentsTab;

  /// Limit of recently used emoji that will be saved
  final int recentsLimit;

  /// The text to be displayed in the search field as a hint
  final String searchHintText;

  /// The text style for [searchHintText]
  final TextStyle? serachHintTextStyle;

  /// The border for the search field when enabled
  final InputBorder? serachBarEnableBorder;

  /// The border for the search field when focused
  final InputBorder? serachBarFocusedBorder;

  /// The text to be displayed if no recent emojis to display
  final String noRecentsText;

  /// The text style for [noRecentsText]
  final TextStyle? noRecentsStyle;

  /// The text to be displayed if no emoji found
  final String noEmojiFoundText;

  /// The color of the scrollbar handle
  final Color? scrollBarHandleColor;

  /// Duration of tab indicator to animate to next category
  final Duration tabIndicatorAnimDuration;

  /// Determines the icon to display for each [Category]
  final CategoryIcons categoryIcons;

  /// Change between Material and Cupertino button style
  final ButtonMode buttonMode;

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

// double check here
  @override
  bool operator ==(other) {
    return (other is EmojiPickerConfig) &&
        other.emojiNumberPerRow == emojiNumberPerRow &&
        other.emojiSizeMax == emojiSizeMax &&
        other.verticalSpacing == verticalSpacing &&
        other.horizontalSpacing == horizontalSpacing &&
        other.initCategory == initCategory &&
        other.bgColor == bgColor &&
        other.categoryIconColor == categoryIconColor &&
        other.selectedCategoryIconColor == selectedCategoryIconColor &&
        other.selectedCategoryIconBackgroundColor ==
            selectedCategoryIconBackgroundColor &&
        other.progressIndicatorColor == progressIndicatorColor &&
        other.backspaceColor == backspaceColor &&
        other.showRecentsTab == showRecentsTab &&
        other.recentsLimit == recentsLimit &&
        other.searchHintText == searchHintText &&
        other.serachHintTextStyle == serachHintTextStyle &&
        other.serachBarEnableBorder == serachBarEnableBorder &&
        other.serachBarFocusedBorder == serachBarFocusedBorder &&
        other.noRecentsText == noRecentsText &&
        other.noRecentsStyle == noRecentsStyle &&
        other.noEmojiFoundText == noEmojiFoundText &&
        other.tabIndicatorAnimDuration == tabIndicatorAnimDuration &&
        other.scrollBarHandleColor == scrollBarHandleColor &&
        other.categoryIcons == categoryIcons &&
        other.buttonMode == buttonMode;
  }

  @override
  int get hashCode =>
      emojiNumberPerRow.hashCode ^
      emojiSizeMax.hashCode ^
      verticalSpacing.hashCode ^
      horizontalSpacing.hashCode ^
      initCategory.hashCode ^
      bgColor.hashCode ^
      categoryIconColor.hashCode ^
      selectedCategoryIconColor.hashCode ^
      selectedCategoryIconBackgroundColor.hashCode ^
      progressIndicatorColor.hashCode ^
      backspaceColor.hashCode ^
      showRecentsTab.hashCode ^
      recentsLimit.hashCode ^
      searchHintText.hashCode ^
      serachHintTextStyle.hashCode ^
      serachBarEnableBorder.hashCode ^
      serachBarFocusedBorder.hashCode ^
      noRecentsText.hashCode ^
      noRecentsStyle.hashCode ^
      noEmojiFoundText.hashCode ^
      scrollBarHandleColor.hashCode ^
      tabIndicatorAnimDuration.hashCode ^
      categoryIcons.hashCode ^
      buttonMode.hashCode;
}
