import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('export markdown to document', () {
    test('file block', () async {
      final document = Document.blank()
        ..insert(
          [0],
          [
            fileNode(
              name: 'file.txt',
              url: 'https://file.com',
            ),
          ],
        );
      final markdown = customDocumentToMarkdown(document);
      expect(markdown, '[file.txt](https://file.com)\n');
    });

    test('link preview', () {
      final document = Document.blank()
        ..insert(
          [0],
          [linkPreviewNode(url: 'https://www.link_preview.com')],
        );
      final markdown = customDocumentToMarkdown(document);
      expect(
        markdown,
        '[https://www.link_preview.com](https://www.link_preview.com)\n',
      );
    });
  });
}
