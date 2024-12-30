import 'package:appflowy/shared/appflowy_cache_manager.dart';
import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;

class CustomImageCacheManager extends CacheManager
    with ImageCacheManager
    implements ICache {
  CustomImageCacheManager._()
      : super(
          Config(
            key,
            fileSystem: CustomIOFileSystem(key),
          ),
        );

  factory CustomImageCacheManager() => _instance;

  static final CustomImageCacheManager _instance = CustomImageCacheManager._();

  static const key = 'image_cache';

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

class CustomIOFileSystem implements FileSystem {
  CustomIOFileSystem(this._cacheKey) : _fileDir = createDirectory(_cacheKey);
  final Future<Directory> _fileDir;
  final String _cacheKey;

  static Future<Directory> createDirectory(String key) async {
    final baseDir = await appFlowyApplicationDataDirectory();
    final path = p.join(baseDir.path, key);

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    final directory = await _fileDir;
    if (!(await directory.exists())) {
      await createDirectory(_cacheKey);
    }
    return directory.childFile(name);
  }
}
