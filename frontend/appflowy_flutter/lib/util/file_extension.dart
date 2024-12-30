import 'dart:io';

extension FileSizeExtension on String {
  int? get fileSize {
    final file = File(this);
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return null;
  }
}
