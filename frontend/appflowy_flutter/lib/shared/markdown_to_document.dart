import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

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
