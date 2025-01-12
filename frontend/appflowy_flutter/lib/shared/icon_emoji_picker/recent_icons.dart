import 'dart:convert';

import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/kv.dart';
import '../../core/config/kv_keys.dart';
import '../../startup/startup.dart';
import 'flowy_icon_emoji_picker.dart';

class RecentIcons {
  static final Map<String, List<String>> _dataMap = {};
  static bool _loaded = false;
  static const maxLength = 20;

  /// To prevent the Recent Icon feature from affecting the unit tests of the Icon Selector.
  @visibleForTesting
  static bool enable = true;

  static Future<void> putEmoji(String id) async {
    await _put(FlowyIconType.emoji, id);
  }

  static Future<void> putIcon(RecentIcon icon) async {
    await _put(
      FlowyIconType.icon,
      jsonEncode(icon.toJson()),
    );
  }

  static Future<List<String>> getEmojiIds() async {
    await _load();
    return _dataMap[FlowyIconType.emoji.name] ?? [];
  }

  static Future<List<RecentIcon>> getIcons() async {
    await _load();
    return getIconsSync();
  }

  static List<RecentIcon> getIconsSync() {
    final iconList = _dataMap[FlowyIconType.icon.name] ?? [];
    try {
      return iconList
          .map(
            (e) => RecentIcon.fromJson(jsonDecode(e) as Map<String, dynamic>),
          )

          /// skip the data that is already stored locally but has an empty
          /// groupName to accommodate the issue of destructive data modifications
          .skipWhile((e) => e.groupName.isEmpty)
          .toList();
    } catch (e) {
      Log.error('RecentIcons getIcons with :$iconList', e);
    }
    return [];
  }

  @visibleForTesting
  static void clear() {
    _dataMap.clear();
    getIt<KeyValueStorage>().set(KVKeys.recentIcons, jsonEncode({}));
  }

  static Future<void> _save() async {
    await getIt<KeyValueStorage>().set(
      KVKeys.recentIcons,
      jsonEncode(_dataMap),
    );
  }

  static Future<void> _load() async {
    if (_loaded || !enable) {
      return;
    }
    final storage = getIt<KeyValueStorage>();
    final value = await storage.get(KVKeys.recentIcons);
    if (value == null || value.isEmpty) {
      _loaded = true;
      return;
    }
    try {
      final data = jsonDecode(value) as Map;
      _dataMap
        ..clear()
        ..addAll(
          Map<String, List<String>>.from(
            data.map((k, v) => MapEntry(k, List<String>.from(v))),
          ),
        );
    } catch (e) {
      Log.error('RecentIcons load failed with: $value', e);
    }
    _loaded = true;
  }

  static Future<void> _put(FlowyIconType key, String value) async {
    await _load();
    if (!enable) return;
    final list = _dataMap[key.name] ?? [];
    list.remove(value);
    list.insert(0, value);
    if (list.length > maxLength) list.removeLast();
    _dataMap[key.name] = list;
    await _save();
  }
}
