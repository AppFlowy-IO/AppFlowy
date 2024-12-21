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
  @visibleForTesting
  static bool enable = true;

  static Future _save() async {
    await getIt<KeyValueStorage>().set(
      KVKeys.kRecentIcons,
      jsonEncode(_dataMap),
    );
  }

  static Future _load() async {
    if (_loaded || !enable) return;
    final v = await getIt<KeyValueStorage>().get(KVKeys.kRecentIcons);
    try {
      final data = jsonDecode(v ?? '') as Map;
      _dataMap.clear();
      _dataMap.addAll(
        data.map(
          (k, v) => MapEntry<String, List<String>>(k, List<String>.from(v)),
        ),
      );
    } on FormatException catch (e) {
      Log.error('RecentIcons load with :$v', e);
    } on TypeError catch (e) {
      Log.error('RecentIcons load with :$v', e);
    }
    _loaded = true;
  }

  static Future _put(FlowyIconType key, String value) async {
    await _load();
    if (!enable) return;
    final list = _dataMap[key.name] ?? [];
    list.remove(value);
    list.insert(0, value);
    if (list.length > maxLength) list.removeLast();
    _dataMap[key.name] = list;
    await _save();
  }

  static Future putEmoji(String id) async {
    await _put(FlowyIconType.emoji, id);
  }

  static Future putIcon(Icon icon) async {
    await _put(
      FlowyIconType.icon,
      jsonEncode(
        Icon(name: icon.name, keywords: icon.keywords, content: icon.content)
            .toJson(),
      ),
    );
  }

  static Future<List<String>> getEmojiIds() async {
    await _load();
    return _dataMap[FlowyIconType.emoji.name] ?? [];
  }

  static Future<List<Icon>> getIcons() async {
    await _load();
    final iconList = _dataMap[FlowyIconType.icon.name] ?? [];
    try {
      return iconList
          .map((e) => Icon.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      Log.error('RecentIcons getIcons with :$iconList', e);
    } on TypeError catch (e) {
      Log.error('RecentIcons getIcons with :$iconList', e);
    }
    return [];
  }
}
