// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/category_models.dart';
import 'config.dart';
import 'default_emoji_picker_view.dart';
import 'models/emoji_model.dart';
import 'emoji_lists.dart' as emoji_list;
import 'emoji_view_state.dart';
import 'models/recent_emoji_model.dart';

/// All the possible categories that [Emoji] can be put into
///
/// All [Category] are shown in the category bar
enum Category {
  /// Searched emojis
  SEARCH,

  /// Recent emojis
  RECENT,

  /// Smiley emojis
  SMILEYS,

  /// Animal emojis
  ANIMALS,

  /// Food emojis
  FOODS,

  /// Activity emojis
  ACTIVITIES,

  /// Travel emojis
  TRAVEL,

  /// Objects emojis
  OBJECTS,

  /// Sumbol emojis
  SYMBOLS,

  /// Flag emojis
  FLAGS,
}

/// Enum to alter the keyboard button style
enum ButtonMode {
  /// Android button style - gives the button a splash color with ripple effect
  MATERIAL,

  /// iOS button style - gives the button a fade out effect when pressed
  CUPERTINO
}

/// Callback function for when emoji is selected
///
/// The function returns the selected [Emoji] as well
/// as the [Category] from which it originated
typedef OnEmojiSelected = void Function(Category category, Emoji emoji);

/// Callback function for backspace button
typedef OnBackspacePressed = void Function();

/// Callback function for custom view
typedef EmojiViewBuilder = Widget Function(Config config, EmojiViewState state);

/// The Emoji Keyboard widget
///
/// This widget displays a grid of [Emoji] sorted by [Category]
/// which the user can horizontally scroll through.
///
/// There is also a bottombar which displays all the possible [Category]
/// and allow the user to quickly switch to that [Category]
class EmojiPicker extends StatefulWidget {
  /// EmojiPicker for flutter
  const EmojiPicker({
    Key? key,
    required this.onEmojiSelected,
    this.onBackspacePressed,
    this.config = const Config(),
    this.customWidget,
  }) : super(key: key);

  /// Custom widget
  final EmojiViewBuilder? customWidget;

  /// The function called when the emoji is selected
  final OnEmojiSelected onEmojiSelected;

  /// The function called when backspace button is pressed
  final OnBackspacePressed? onBackspacePressed;

  /// Config for customizations
  final Config config;

  @override
  EmojiPickerState createState() => EmojiPickerState();
}

class EmojiPickerState extends State<EmojiPicker> {
  static const platform = MethodChannel('emoji_picker_flutter');

  List<CategoryEmoji> categoryEmoji = List.empty(growable: true);
  List<RecentEmoji> recentEmoji = List.empty(growable: true);
  late Future<void> updateEmojiFuture;

  // Prevent emojis to be reloaded with every build
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    updateEmojiFuture = _updateEmojis();
  }

  @override
  void didUpdateWidget(covariant EmojiPicker oldWidget) {
    if (oldWidget.config != widget.config) {
      // Config changed - rebuild EmojiPickerView completely
      loaded = false;
      updateEmojiFuture = _updateEmojis();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      // Load emojis
      updateEmojiFuture.then(
        (value) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            loaded = true;
          });
        }),
      );

      // Show loading indicator
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.config.showRecentsTab) {
      categoryEmoji[0].emoji =
          recentEmoji.map((e) => e.emoji).toList().cast<Emoji>();
    }

    final state = EmojiViewState(
      categoryEmoji,
      _getOnEmojiListener(),
      widget.onBackspacePressed,
    );

    // Build
    return widget.customWidget == null
        ? DefaultEmojiPickerView(widget.config, state)
        : widget.customWidget!(widget.config, state);
  }

  // Add recent emoji handling to tap listener
  OnEmojiSelected _getOnEmojiListener() {
    return (category, emoji) {
      if (widget.config.showRecentsTab) {
        _addEmojiToRecentlyUsed(emoji).then((value) {
          if (category != Category.RECENT && mounted) {
            setState(() {
              // rebuild to update recent emoji tab
              // when it is not current tab
            });
          }
        });
      }
      widget.onEmojiSelected(category, emoji);
    };
  }

  // Initialize emoji data
  Future<void> _updateEmojis() async {
    categoryEmoji.clear();
    if (widget.config.showRecentsTab) {
      recentEmoji = await _getRecentEmojis();
      final List<Emoji> recentEmojiMap =
          recentEmoji.map((e) => e.emoji).toList().cast<Emoji>();
      categoryEmoji.add(CategoryEmoji(Category.RECENT, recentEmojiMap));
    }
    categoryEmoji.addAll([
      CategoryEmoji(Category.SMILEYS,
          await _getAvailableEmojis(emoji_list.smileys, title: 'smileys'),),
      CategoryEmoji(Category.ANIMALS,
          await _getAvailableEmojis(emoji_list.animals, title: 'animals'),),
      CategoryEmoji(Category.FOODS,
          await _getAvailableEmojis(emoji_list.foods, title: 'foods'),),
      CategoryEmoji(
          Category.ACTIVITIES,
          await _getAvailableEmojis(emoji_list.activities,
              title: 'activities',),),
      CategoryEmoji(Category.TRAVEL,
          await _getAvailableEmojis(emoji_list.travel, title: 'travel'),),
      CategoryEmoji(Category.OBJECTS,
          await _getAvailableEmojis(emoji_list.objects, title: 'objects'),),
      CategoryEmoji(Category.SYMBOLS,
          await _getAvailableEmojis(emoji_list.symbols, title: 'symbols'),),
      CategoryEmoji(Category.FLAGS,
          await _getAvailableEmojis(emoji_list.flags, title: 'flags'),)
    ]);
  }

  // Get available emoji for given category title
  Future<List<Emoji>> _getAvailableEmojis(Map<String, String> map,
      {required String title,}) async {
    Map<String, String>? newMap;

    // Get Emojis cached locally if available
    newMap = await _restoreFilteredEmojis(title);

    if (newMap == null) {
      // Check if emoji is available on this platform
      newMap = await _getPlatformAvailableEmoji(map);
      // Save available Emojis to local storage for faster loading next time
      if (newMap != null) {
        await _cacheFilteredEmojis(title, newMap);
      }
    }

    // Map to Emoji Object
    return newMap!.entries
        .map<Emoji>((entry) => Emoji(entry.key, entry.value))
        .toList();
  }

  // Check if emoji is available on current platform
  Future<Map<String, String>?> _getPlatformAvailableEmoji(
      Map<String, String> emoji,) async {
    if (Platform.isAndroid) {
      Map<String, String>? filtered = {};
      const delimiter = '|';
      try {
        final entries = emoji.values.join(delimiter);
        final keys = emoji.keys.join(delimiter);
        final result = (await platform.invokeMethod<String>('checkAvailability',
            {'emojiKeys': keys, 'emojiEntries': entries},)) as String;
        final resultKeys = result.split(delimiter);
        for (var i = 0; i < resultKeys.length; i++) {
          filtered[resultKeys[i]] = emoji[resultKeys[i]]!;
        }
      } on PlatformException catch (_) {
        filtered = null;
      }
      return filtered;
    } else {
      return emoji;
    }
  }

  // Restore locally cached emoji
  Future<Map<String, String>?> _restoreFilteredEmojis(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final emojiJson = prefs.getString(title);
    if (emojiJson == null) {
      return null;
    }
    final emojis =
        Map<String, String>.from(jsonDecode(emojiJson) as Map<String, dynamic>);
    return emojis;
  }

  // Stores filtered emoji locally for faster access next time
  Future<void> _cacheFilteredEmojis(
      String title, Map<String, String> emojis,) async {
    final prefs = await SharedPreferences.getInstance();
    final emojiJson = jsonEncode(emojis);
    prefs.setString(title, emojiJson);
  }

  // Returns list of recently used emoji from cache
  Future<List<RecentEmoji>> _getRecentEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    final emojiJson = prefs.getString('recent');
    if (emojiJson == null) {
      return [];
    }
    final json = jsonDecode(emojiJson) as List<dynamic>;
    return json.map<RecentEmoji>(RecentEmoji.fromJson).toList();
  }

  // Add an emoji to recently used list or increase its counter
  Future<void> _addEmojiToRecentlyUsed(Emoji emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final recentEmojiIndex =
        recentEmoji.indexWhere((element) => element.emoji.emoji == emoji.emoji);
    if (recentEmojiIndex != -1) {
      // Already exist in recent list
      // Just update counter
      recentEmoji[recentEmojiIndex].counter++;
    } else {
      recentEmoji.add(RecentEmoji(emoji, 1));
    }
    // Sort by counter desc
    recentEmoji.sort((a, b) => b.counter - a.counter);
    // Limit entries to recentsLimit
    recentEmoji = recentEmoji.sublist(
        0, min(widget.config.recentsLimit, recentEmoji.length),);
    // save locally
    prefs.setString('recent', jsonEncode(recentEmoji));
  }
}
