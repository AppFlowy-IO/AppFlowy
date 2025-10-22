import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/markdown_latex_utils.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/markdown_math_equation_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/sub_page_node_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Convert Markdown to an AppFlowy [Document], with optional table width.
Document customMarkdownToDocument(
  String markdown, {
  double? tableWidth,
}) {
  final String preprocessed = _preprocessLatexBlocks(markdown);

  return markdownToDocument(
    preprocessed,
    markdownParsers: [
      const MarkdownMathEquationParser(),
      const MarkdownCodeBlockParser(),
      MarkdownSimpleTableParser(tableWidth: tableWidth),
    ],
  );
}

/// Find custom bracketed LaTeX blocks and convert them to `$$ ... $$`.
///
/// This preprocessor runs before markdown parsing to handle LaTeX content
/// in square brackets that contains actual newlines (not yet collapsed by markdown).
String _preprocessLatexBlocks(String markdown) {
  return markdown.replaceAllMapped(latexBlockRegex, (Match match) {
    String content = match.group(1) ?? '';
    content = content.replaceAll(RegExp(r'^\s+|\s+$'), '');

    if (containsLaTeX(content)) {
      content = fixLatexLineBreaksWithNewlines(content);
      content = fixLatexSpacing(content);
      return '\$\$\n$content\n\$\$';
    }
    return match.group(0) ?? '';
  });
}

/// Convert an AppFlowy [Document] to Markdown and optionally create/archive resources.
Future<String> customDocumentToMarkdown(
  Document document, {
  String path = '',
  AsyncValueSetter<Archive>? onArchive,
  String lineBreak = '',
}) async {
  final List<Future<ArchiveFile>> fileFutures = <Future<ArchiveFile>>[];

  // create root Archive and directory
  final String id = document.root.id;
  final Archive archive = Archive();
  final ArchiveFile resourceDir =
      ArchiveFile('$id/', 0, null)..isFile = false;
  final String fileName = p.basenameWithoutExtension(path);
  final String dirName = resourceDir.name;

  String markdown = '';
  try {
    markdown = documentToMarkdown(
      document,
      lineBreak: lineBreak,
      customParsers: [
        const MathEquationNodeParser(),
        const CalloutNodeParser(),
        const ToggleListNodeParser(),
        CustomImageNodeFileParser(fileFutures, dirName),
        CustomMultiImageNodeFileParser(fileFutures, dirName),
        GridNodeParser(fileFutures, dirName),
        BoardNodeParser(fileFutures, dirName),
        CalendarNodeParser(fileFutures, dirName),
        const CustomParagraphNodeParser(),
        const SubPageNodeParser(),
        const SimpleTableNodeParser(),
        const LinkPreviewNodeParser(),
        const FileBlockNodeParser(),
      ],
    );
  } catch (e) {
    Log.error('documentToMarkdown error: $e');
  }

  // create resource directory
  if (fileFutures.isNotEmpty) {
    archive.addFile(resourceDir);
  }

  for (final Future<ArchiveFile> fileFuture in fileFutures) {
    archive.addFile(await fileFuture);
  }

  // add markdown file to Archive
  final List<int> dataBytes = utf8.encode(markdown);
  archive.addFile(ArchiveFile('$fileName-$id.md', dataBytes.length, dataBytes));

  if (archive.isNotEmpty && path.isNotEmpty) {
    if (onArchive == null) {
      final ZipEncoder zipEncoder = ZipEncoder();
      final List<int>? zip = zipEncoder.encode(archive);
      if (zip != null) {
        final File zipFile = await File(path).writeAsBytes(zip);
        if (Platform.isIOS) {
          await Share.shareUri(zipFile.uri);
          await zipFile.delete();
        } else if (Platform.isAndroid) {
          await Share.shareXFiles([XFile(zipFile.path)]);
          await zipFile.delete();
        }
        Log.info('documentToMarkdownFiles to $path');
      }
    } else {
      await onArchive.call(archive);
    }
  }
  return markdown;
}
