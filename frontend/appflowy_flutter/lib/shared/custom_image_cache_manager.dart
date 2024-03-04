import 'package:appflowy/shared/appflowy_cache_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomImageCacheManager extends CacheManager
    with ImageCacheManager
    implements ICache {
  CustomImageCacheManager._() : super(Config(key));

  factory CustomImageCacheManager() => _instance;

  static final CustomImageCacheManager _instance = CustomImageCacheManager._();

  static const key = 'appflowy_image_cache';

  @override
  Future<int> cacheSize() async {
    // https://github.com/Baseflow/flutter_cache_manager/issues/239#issuecomment-719475429
    // this package does not provide a way to get the cache size
    return 0;
  }

  @override
  Future<void> clearAll() async {
    await emptyCache();
  }
}
