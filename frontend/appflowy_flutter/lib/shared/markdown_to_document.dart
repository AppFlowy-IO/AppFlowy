import 'dart:convert';
import 'dart:io';

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
String _preprocessLatexBlocks(String markdown) {
  final RegExp latexBlockRegex = RegExp(
    r'^\[\s*\n((?:.*\n)*?.*?)\s*\]$',
    multiLine: true,
  );

  return markdown.replaceAllMapped(latexBlockRegex, (Match match) {
    String content = match.group(1) ?? '';
    content = content.replaceAll(RegExp(r'^\s+|\s+$'), '');

    if (_containsLaTeX(content)) {
      content = _fixLatexLineBreaks(content);
      content = _fixLatexSpacing(content);
      return '\$\$\n$content\n\$\$';
    }
    return match.group(0) ?? '';
  });
}

/// Ensure common spacing in LaTeX (e.g. `\, dx`).
String _fixLatexSpacing(String latex) {
  String result = latex;
  result = result.replaceAll(', dx', r'\, dx');
  result = result.replaceAll(', dy', r'\, dy');
  result = result.replaceAll(', dz', r'\, dz');
  result = result.replaceAll(', dt', r'\, dt');
  result = result.replaceAll(', dV', r'\, dV');
  result = result.replaceAll(', dA', r'\, dA');
  result = result.replaceAll(', ds', r'\, ds');
  result = result.replaceAll(', du', r'\, du');
  result = result.replaceAll(', dv', r'\, dv');
  result = result.replaceAll(', dw', r'\, dw');
  return result;
}

/// Fix line breaks inside LaTeX environments so rows end with `\\\\` where needed.
String _fixLatexLineBreaks(String latex) {
  final bool hasEnvironment = latex.contains(r'\begin{cases}') ||
      latex.contains(r'\begin{aligned}') ||
      latex.contains(r'\begin{array}');

  if (!hasEnvironment) {
    return latex;
  }

  final List<String> lines = latex.split('\n');
  final List<String> result = <String>[];
  bool inEnvironment = false;

  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];

    if (line.contains(r'\begin{cases}') ||
        line.contains(r'\begin{aligned}') ||
        line.contains(r'\begin{array}')) {
      inEnvironment = true;
      result.add(line);
      continue;
    }

    if (line.contains(r'\end{cases}') ||
        line.contains(r'\end{aligned}') ||
        line.contains(r'\end{array}')) {
      inEnvironment = false;
      result.add(line);
      continue;
    }

    if (!inEnvironment) {
      result.add(line);
      continue;
    }

    final String trimmed = line.trimRight();

    if (trimmed.isEmpty) {
      result.add(line);
      continue;
    }

    if (trimmed.endsWith(r'\\')) {
      result.add(line);
      continue;
    }

    // compare single backslash correctly
    if (trimmed.isNotEmpty && trimmed[trimmed.length - 1] == '\\') {
      if (trimmed.length < 2 || trimmed[trimmed.length - 2] != '\\') {
        final String withoutSlash = trimmed.substring(0, trimmed.length - 1);
        final String trailingSpaces = line.substring(trimmed.length);
        result.add('$withoutSlash\\\\$trailingSpaces');
        continue;
      }
    }

    if (i + 1 < lines.length) {
      final String nextLine = lines[i + 1].trim();
      if (nextLine.startsWith(r'\end{cases}') ||
          nextLine.startsWith(r'\end{aligned}') ||
          nextLine.startsWith(r'\end{array}')) {
        result.add(line);
        continue;
      }
    }

    result.add('$trimmed \\\\');
  }

  return result.join('\n');
}

/// Heuristic check whether the content likely contains LaTeX.
bool _containsLaTeX(String content) => content.contains(r'\int') ||
    content.contains(r'\sum') ||
    content.contains(r'\frac') ||
    content.contains(r'\lim') ||
    content.contains(r'\text') ||
    content.contains(r'\begin') ||
    content.contains(r'\iint') ||
    content.contains(r'\iiint') ||
    content.contains(RegExp(r'\\[a-zA-Z]+')) ||
    content.contains(RegExp(r'[_^]\{')) ||
    content.contains(RegExp(r'[a-zA-Z0-9]\s*[+\-*/=]\s*[a-zA-Z0-9]')) ||
    content.contains(RegExp(r'\^[0-9]'));

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
