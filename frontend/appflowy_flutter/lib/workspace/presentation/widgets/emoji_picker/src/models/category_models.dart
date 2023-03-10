import 'package:flutter/material.dart';

import 'emoji_model.dart';
import '../emoji_picker.dart';

/// Container for Category and their emoji
class CategoryEmoji {
  /// Constructor
  CategoryEmoji(this.category, this.emoji);

  /// Category instance
  final Category category;

  /// List of emoji of this category
  List<Emoji> emoji;

  @override
  String toString() {
    return 'Name: $category, Emoji: $emoji';
  }
}

/// Class that defines the icon representing a [Category]
class CategoryIcon {
  /// Icon of Category
  const CategoryIcon({
    required this.icon,
    this.color = const Color.fromRGBO(211, 211, 211, 1),
    this.selectedColor = const Color.fromRGBO(178, 178, 178, 1),
  });

  /// The icon to represent the category
  final IconData icon;

  /// The default color of the icon
  final Color color;

  /// The color of the icon once the category is selected
  final Color selectedColor;
}

/// Class used to define all the [CategoryIcon] shown for each [Category]
///
/// This allows the keyboard to be personalized by changing icons shown.
/// If a [CategoryIcon] is set as null or not defined during initialization,
/// the default icons will be used instead
class CategoryIcons {
  /// Constructor
  const CategoryIcons({
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

  /// Icon for [Category.RECENT]
  final IconData recentIcon;

  /// Icon for [Category.SMILEYS]
  final IconData smileyIcon;

  /// Icon for [Category.ANIMALS]
  final IconData animalIcon;

  /// Icon for [Category.FOODS]
  final IconData foodIcon;

  /// Icon for [Category.ACTIVITIES]
  final IconData activityIcon;

  /// Icon for [Category.TRAVEL]
  final IconData travelIcon;

  /// Icon for [Category.OBJECTS]
  final IconData objectIcon;

  /// Icon for [Category.SYMBOLS]
  final IconData symbolIcon;

  /// Icon for [Category.FLAGS]
  final IconData flagIcon;

  /// Icon for [Category.SEARCH]
  final IconData searchIcon;
}
