import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

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

Future<void> unzipFile(File zipFile, Directory targetDirectory) async {
  // Read the Zip file from disk.
  final bytes = zipFile.readAsBytesSync();

  // Decode the Zip file
  final archive = ZipDecoder().decodeBytes(bytes);

  // Extract the contents of the Zip archive to disk.
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File(p.join(targetDirectory.path, filename))
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory(p.join(targetDirectory.path, filename))
          .createSync(recursive: true);
    }
  }
}
