import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';

class TabsService {
  const TabsService();

  static Future<void> setPluginClosedInCache(String pluginId) async {
    final result = await getIt<KeyValueStorage>().get(KVKeys.openedPlugins);
    final map = result.fold(
      (l) => {},
      (r) => jsonDecode(r),
    );
    if (map[pluginId] != null) {
      map[pluginId] -= 1;

      if (map[pluginId] <= 0) {
        map.remove(pluginId);
      }
    }
    await getIt<KeyValueStorage>().set(KVKeys.openedPlugins, jsonEncode(map));
  }

  static Future<bool> setPluginOpenedInCache(Plugin plugin) async {
    final result = await getIt<KeyValueStorage>().get(KVKeys.openedPlugins);
    final map = result.fold(
      (l) => {},
      (r) => jsonDecode(r),
    );
    // Log.warn("Result Map $map ${map[plugin.id]} ${plugin.id}");
    if (map[plugin.id] != null) {
      map[plugin.id] += 1;
      return true;
    }

    map[plugin.id] = 1;
    Log.warn(map);
    await getIt<KeyValueStorage>().set(KVKeys.openedPlugins, jsonEncode(map));
    return false;
  }
}
