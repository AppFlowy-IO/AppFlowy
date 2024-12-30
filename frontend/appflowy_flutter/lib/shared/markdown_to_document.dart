import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

Document customMarkdownToDocument(String markdown) {
  return markdownToDocument(
    markdown,
    markdownParsers: [
      const MarkdownCodeBlockParser(),
      const MarkdownSimpleTableParser(),
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
