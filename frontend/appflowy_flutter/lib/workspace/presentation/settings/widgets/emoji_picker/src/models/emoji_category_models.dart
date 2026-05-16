import 'package:flutter/material.dart';

import 'emoji_model.dart';
import '../emoji_picker.dart';

/// EmojiCategory with its emojis
class EmojiCategoryGroup {
  EmojiCategoryGroup(this.category, this.emoji);

  final EmojiCategory category;

  /// List of emoji of this category
  List<Emoji> emoji;

  @override
  String toString() {
    return 'Name: $category, Emoji: $emoji';
  }
}

/// Class that defines the icon representing a [EmojiCategory]
class EmojiCategoryIcon {
  /// Icon of Category
  const EmojiCategoryIcon({
    required this.icon,
    this.color = const Color(0xffd3d3d3),
    this.selectedColor = const Color(0xffb2b2b2),
  });

  /// The icon to represent the category
  final IconData icon;

  /// The default color of the icon
  final Color color;

  /// The color of the icon once the category is selected
  final Color selectedColor;
}

/// Class used to define all the [EmojiCategoryIcon] shown for each [EmojiCategory]
///
/// This allows the keyboard to be personalized by changing icons shown.
/// If a [EmojiCategoryIcon] is set as null or not defined during initialization,
/// the default icons will be used instead
class EmojiCategoryIcons {
  /// Constructor
  const EmojiCategoryIcons({
    this.recentIcon = Icons.access_time,
    this.smileyIcon = Icons.tag_faces,
    this.animalIcon = Icons.pets,
    this.foodIcon = Icons.fastfood,
    this.activityIcon = Icons.directions_run,
    this.travelIcon = Icons.location_city,
    this.objectIcon = Icons.lightbulb_outline,
    this.symbolIcon = Icons.emoji_symbols,
    this.flagIcon = Icons.flag,
    this.searchIcon = Icons.search,
  });

  /// Icon for [EmojiCategory.RECENT]
  final IconData recentIcon;

  /// Icon for [EmojiCategory.SMILEYS]
  final IconData smileyIcon;

  /// Icon for [EmojiCategory.ANIMALS]
  final IconData animalIcon;

  /// Icon for [EmojiCategory.FOODS]
  final IconData foodIcon;

  /// Icon for [EmojiCategory.ACTIVITIES]
  final IconData activityIcon;

  /// Icon for [EmojiCategory.TRAVEL]
  final IconData travelIcon;

  /// Icon for [EmojiCategory.OBJECTS]
  final IconData objectIcon;

  /// Icon for [EmojiCategory.SYMBOLS]
  final IconData symbolIcon;

  /// Icon for [EmojiCategory.FLAGS]
  final IconData flagIcon;

  /// Icon for [EmojiCategory.SEARCH]
  final IconData searchIcon;
}
