import 'dart:io';
import 'dart:typed_data';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:flowy_infra/uuid.dart';
import 'package:path/path.dart' as p;

extension PasteFromImage on EditorState {
  static final supportedImageFormats = [
    'png',
    'jpeg',
    'gif',
  ];

  Future<void> pasteImage(String format, Uint8List imageBytes) async {
    if (!supportedImageFormats.contains(format)) {
      return;
    }

    final path = await getIt<ApplicationDataStorage>().getPath();
    final imagePath = p.join(
      path,
      'images',
    );
    try {
      // create the directory if not exists
      final directory = Directory(imagePath);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      final copyToPath = p.join(
        imagePath,
        '${uuid()}.$format',
      );
      await File(copyToPath).writeAsBytes(imageBytes);
      await insertImageNode(copyToPath);
    } catch (e) {
      Log.error('cannot copy image file', e);
    }
  }
}
