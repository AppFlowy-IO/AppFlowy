import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/database_node_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

Document customMarkdownToDocument(
  String markdown, {
  double? tableWidth,
}) {
  return markdownToDocument(
    markdown,
    markdownParsers: [
      const MarkdownCodeBlockParser(),
      MarkdownSimpleTableParser(tableWidth: tableWidth),
    ],
  );
}

String customDocumentToMarkdown(Document document) {
  return documentToMarkdown(
    document,
    customParsers: [
      const MathEquationNodeParser(),
      const CalloutNodeParser(),
      const ToggleListNodeParser(),
      const CustomImageNodeParser(),
      const SimpleTableNodeParser(),
      const LinkPreviewNodeParser(),
      const FileBlockNodeParser(),
    ],
  );
}

Future<String> documentToMarkdownFiles(Document document, String path) async {
  final List<Future<ArchiveFile>> fileFutures = [];
  final id = document.root.id;

  /// create root Archive
  final archive = Archive();
  final fileName = p.basenameWithoutExtension(path);

  /// create directory
  final resourceDir = ArchiveFile('$id/', 0, null);
  resourceDir.isFile = false;

  final markdown = documentToMarkdown(
    document,
    customParsers: [
      const MathEquationNodeParser(),
      const CalloutNodeParser(),
      const ToggleListNodeParser(),
      CustomImageNodeFileParser(fileFutures, resourceDir.name),
      CustomMultiImageNodeFileParser(fileFutures, resourceDir.name),
      GridNodeParser(fileFutures, resourceDir.name),
      BoardNodeParser(fileFutures, resourceDir.name),
      CalendarNodeParser(fileFutures, resourceDir.name),
      const SimpleTableNodeParser(),
      const LinkPreviewNodeParser(),
      const FileBlockNodeParser(),
    ],
  );

  /// create resource directory
  if (fileFutures.isNotEmpty) archive.addFile(resourceDir);

  /// add markdown file to Archive
  archive.addFile(ArchiveFile.string('$fileName-$id.md', markdown));

  for (final fileFuture in fileFutures) {
    archive.addFile(await fileFuture);
  }
  if (archive.isNotEmpty) {
    final zipEncoder = ZipEncoder();
    final zip = zipEncoder.encode(archive);
    if (zip != null) {
      final zipFile = await File(path).writeAsBytes(zip);
      if (Platform.isIOS) {
        await Share.shareUri(zipFile.uri);
        await zipFile.delete();
      } else if (Platform.isAndroid) {
        await Share.shareXFiles([XFile(zipFile.path)]);
        await zipFile.delete();
      }
      Log.info('documentToMarkdownFiles to $path');
    }
  }
  return markdown;
}
