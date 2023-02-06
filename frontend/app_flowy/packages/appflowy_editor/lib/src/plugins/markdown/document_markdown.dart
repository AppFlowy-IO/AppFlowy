library delta_markdown;

import 'dart:convert';

import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/plugins/markdown/decoder/document_markdown_decoder.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/document_markdown_encoder.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/image_node_parser.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/node_parser.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/text_node_parser.dart';

/// Converts a markdown to [Document].
///
/// [customParsers] is a list of custom parsers that will be used to parse the markdown.
Document markdownToDocument(
  String markdown, {
  List<NodeParser> customParsers = const [],
}) {
  return const AppFlowyEditorMarkdownCodec().decode(markdown);
}

/// Converts a [Document] to markdown.
///
/// [customParsers] is a list of custom parsers that will be used to parse the markdown.
String documentToMarkdown(Document document,
    {List<NodeParser> customParsers = const []}) {
  return AppFlowyEditorMarkdownCodec(encodeParsers: [
    ...customParsers,
    const TextNodeParser(),
    const ImageNodeParser(),
  ]).encode(document);
}

class AppFlowyEditorMarkdownCodec extends Codec<Document, String> {
  const AppFlowyEditorMarkdownCodec({
    this.encodeParsers = const [],
  });

  final List<NodeParser> encodeParsers;

  // TODO: Add support for custom parsers
  @override
  Converter<String, Document> get decoder => DocumentMarkdownDecoder();

  @override
  Converter<Document, String> get encoder => DocumentMarkdownEncoder(
        parsers: encodeParsers,
      );
}
