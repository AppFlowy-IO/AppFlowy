import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy_backend/log.dart';
import 'package:path_provider/path_provider.dart';

class FlowyCacheManager {
  final _caches = <ICache>[];

  // if you add a new cache, you should register it here.
  void registerCache(ICache cache) {
    _caches.add(cache);
  }

  void unregisterAllCache(ICache cache) {
    _caches.clear();
  }

  Future<void> clearAllCache() async {
    try {
      for (final cache in _caches) {
        await cache.clearAll();
      }

      Log.info('Cache cleared');
    } catch (e) {
      Log.error(e);
    }
  }

  Future<int> getCacheSize() async {
    try {
      int tmpDirSize = 0;
      for (final cache in _caches) {
        tmpDirSize += await cache.cacheSize();
      }
      Log.info('Cache size: $tmpDirSize');
      return tmpDirSize;
    } catch (e) {
      Log.error(e);
      return 0;
    }
  }
}

abstract class ICache {
  Future<int> cacheSize();
  Future<void> clearAll();
}

class TemporaryDirectoryCache implements ICache {
  @override
  Future<int> cacheSize() async {
    final tmpDir = await getTemporaryDirectory();
    final tmpDirStat = await tmpDir.stat();
    return tmpDirStat.size;
  }

  @override
  Future<void> clearAll() async {
    final tmpDir = await getTemporaryDirectory();
    await tmpDir.delete(recursive: true);
  }
}

class FeatureFlagCache implements ICache {
  @override
  Future<int> cacheSize() async {
    return 0;
  }

  @override
  Future<void> clearAll() async {
    await FeatureFlag.clear();
  }
}
