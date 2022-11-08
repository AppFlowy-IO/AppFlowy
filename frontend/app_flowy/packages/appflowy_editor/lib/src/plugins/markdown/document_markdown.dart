library delta_markdown;

import 'dart:convert';

import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/document_markdown_encoder.dart';

/// Codec used to convert between Markdown and AppFlowy Editor Document.
const AppFlowyEditorMarkdownCodec _kCodec = AppFlowyEditorMarkdownCodec();

Document markdownToDocument(String markdown) {
  return _kCodec.decode(markdown);
}

String documentToMarkdown(Document document) {
  return _kCodec.encode(document);
}

class AppFlowyEditorMarkdownCodec extends Codec<Document, String> {
  const AppFlowyEditorMarkdownCodec();

  @override
  Converter<String, Document> get decoder => throw UnimplementedError();

  @override
  Converter<Document, String> get encoder {
    return DocumentMarkdownEncoder();
  }
}
