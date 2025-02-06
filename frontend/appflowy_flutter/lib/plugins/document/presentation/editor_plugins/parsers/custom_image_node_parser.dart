import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../image/custom_image_block_component/custom_image_block_component.dart';

class CustomImageNodeParser extends NodeParser {
  const CustomImageNodeParser();

  @override
  String get id => ImageBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    assert(node.children.isEmpty);
    final url = node.attributes[CustomImageBlockKeys.url];
    assert(url != null);
    return '![]($url)\n';
  }
}

class CustomImageNodeFileParser extends NodeParser {
  const CustomImageNodeFileParser(this.files, this.dirPath);

  final List<Future<ArchiveFile>> files;
  final String dirPath;

  @override
  String get id => ImageBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    assert(node.children.isEmpty);
    final url = node.attributes[CustomImageBlockKeys.url];
    final hasFile = File(url).existsSync();
    if (hasFile) {
      final bytes = File(url).readAsBytesSync();
      files.add(
        Future.value(
          ArchiveFile(p.join(dirPath, p.basename(url)), bytes.length, bytes),
        ),
      );
      return '![](${p.join(dirPath, p.basename(url))})\n';
    }
    assert(url != null);
    return '![]($url)\n';
  }
}

class CustomMultiImageNodeFileParser extends NodeParser {
  const CustomMultiImageNodeFileParser(this.files, this.dirPath);

  final List<Future<ArchiveFile>> files;
  final String dirPath;

  @override
  String get id => MultiImageBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    assert(node.children.isEmpty);
    final images = node.attributes[MultiImageBlockKeys.images] as List;
    final List<String> markdownImages = [];
    for (final image in images) {
      final String url = image['url'] ?? '';
      if (url.isEmpty) continue;
      final hasFile = File(url).existsSync();
      if (hasFile) {
        final bytes = File(url).readAsBytesSync();
        final filePath = p.join(dirPath, p.basename(url));
        files.add(
          Future.value(ArchiveFile(filePath, bytes.length, bytes)),
        );
        markdownImages.add('![]($filePath)');
      } else {
        markdownImages.add('![]($url})');
      }
    }
    return markdownImages.join('\n\n');
  }
}
