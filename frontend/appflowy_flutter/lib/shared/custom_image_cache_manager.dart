import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomImageCacheManager extends CacheManager with ImageCacheManager {
  CustomImageCacheManager._() : super(Config(key));

  factory CustomImageCacheManager() => _instance;

  static final CustomImageCacheManager _instance = CustomImageCacheManager._();

  static const key = 'appflowy_image_cache';
}
