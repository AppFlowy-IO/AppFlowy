import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> deleteDirectoriesWithSameBaseNameAsPrefix(
  String path,
) async {
  final dir = Directory(path);
  final prefix = p.basename(dir.path);
  final parentDir = dir.parent;

  // Check if the directory exists
  if (!await parentDir.exists()) {
    // ignore: avoid_print
    print('Directory does not exist');
    return;
  }

  // List all entities in the directory
  await for (final entity in parentDir.list()) {
    // Check if the entity is a directory and starts with the specified prefix
    if (entity is Directory && p.basename(entity.path).startsWith(prefix)) {
      try {
        await entity.delete(recursive: true);
      } catch (e) {
        // ignore: avoid_print
        print('Failed to delete directory: ${entity.path}, Error: $e');
      }
    }
  }
}
