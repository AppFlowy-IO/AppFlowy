import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'appflowy_image_cache';

  factory CustomImageCacheManager() {
    return _instance;
  }

  static final CustomImageCacheManager _instance = CustomImageCacheManager._();

  CustomImageCacheManager._() : super(Config(key));
}
