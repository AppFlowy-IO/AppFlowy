import 'dart:convert';
import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/application/settings/share/import_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/import/import_panel.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/import/import_type.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:archive/archive_io.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class NotionImporter {
  NotionImporter({
    required this.parentViewId,
  });

  final String parentViewId;

  final markdownImageRegex = RegExp(r'^!\[[^\]]*\]\((.*?)\)');

  Future<void> importFromNotion(ImportFromNotionType type, String path) async {
    switch (type) {
      case ImportFromNotionType.markdownZip:
        await _importFromMarkdownZip(path);
        break;
    }
    return;
  }

  Future<void> _importFromMarkdownZip(String path) async {
    final zip = File(path);
    final bytes = await zip.readAsBytes();
    final unzipFiles = ZipDecoder().decodeBytes(bytes);
    final markdownFile = unzipFiles.firstWhereOrNull(
      (element) =>
          element.isFile &&
          element.name.endsWith('.md') &&
          !element.name.contains("/"),
    );
    if (markdownFile == null) {
      return;
    }

    final name = p.basenameWithoutExtension(markdownFile.name);

    // save the images
    final images = unzipFiles.where(
      (element) {
        final extension = p.extension(element.name);
        return element.isFile &&
            ['.png', '.jpg', '.jpeg'].contains(extension) &&
            element.name.split('/').length - 1 == 1;
      },
    );

    final markdownContents = utf8.decode(markdownFile.content as Uint8List);
    final processedMarkdownFile = await _preProcessMarkdownFile(
      markdownContents,
      images,
    );
    final data = documentDataFrom(
      ImportType.markdownOrText,
      processedMarkdownFile,
    );
    if (data != null) {
      await ImportBackendService.importData(
        data,
        name,
        parentViewId,
        ImportTypePB.HistoryDocument,
      );
    }
  }

  Future<String> _preProcessMarkdownFile(
    String markdown,
    Iterable<ArchiveFile> images,
  ) async {
    if (images.isEmpty) {
      return markdown;
    }

    final lines = markdown.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (line.isEmpty) {
        continue;
      }
      if (!markdownImageRegex.hasMatch(line.trim())) {
        result.add(line);
      } else {
        final imagePath = markdownImageRegex.firstMatch(line)?.group(1);
        if (imagePath == null) {
          result.add(line);
        } else {
          final image = images.firstWhereOrNull(
            (element) => element.name == Uri.decodeFull(imagePath),
          );
          if (image == null) {
            result.add(line);
          } else {
            final localPath = await _saveImage(
              image,
            );
            result.add(line.replaceFirst(imagePath, localPath));
          }
        }
      }
    }
    return result.join('\n');
  }

  Future<String> _saveImage(ArchiveFile image) async {
    final path = await getIt<ApplicationDataStorage>().getPath();
    final imagePath = p.join(path, 'images');
    final directory = Directory(imagePath);
    await directory.create(recursive: true);
    final copyToPath = p.join(imagePath, '${uuid()}${p.extension(image.name)}');
    await File(copyToPath).writeAsBytes(image.content as Uint8List);
    return copyToPath;
  }
}
