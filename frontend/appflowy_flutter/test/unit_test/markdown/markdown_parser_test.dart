import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
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
      final markdown = await customDocumentToMarkdown(document);
      expect(markdown, '[file.txt](https://file.com)\n');
    });

    test('link preview', () async {
      final document = Document.blank()
        ..insert(
          [0],
          [linkPreviewNode(url: 'https://www.link_preview.com')],
        );
      final markdown = await customDocumentToMarkdown(document);
      expect(
        markdown,
        '[https://www.link_preview.com](https://www.link_preview.com)\n',
      );
    });

    test('multiple images', () async {
      const png1 = 'https://www.appflowy.png',
          png2 = 'https://www.appflowy2.png';
      final document = Document.blank()
        ..insert(
          [0],
          [
            multiImageNode(
              images: [
                ImageBlockData(
                  url: png1,
                  type: CustomImageType.external,
                ),
                ImageBlockData(
                  url: png2,
                  type: CustomImageType.external,
                ),
              ],
            ),
          ],
        );
      final markdown = await customDocumentToMarkdown(document);
      expect(
        markdown,
        '![]($png1)\n![]($png2)',
      );
    });

    test('subpage block', () async {
      const testSubpageId = 'testSubpageId';
      final subpageNode = pageMentionNode(testSubpageId);
      final document = Document.blank()
        ..insert(
          [0],
          [subpageNode],
        );
      final markdown = await customDocumentToMarkdown(document);
      expect(
        markdown,
        '[]($testSubpageId)\n',
      );
    });

    test('date or reminder', () async {
      final dateTime = DateTime.now();
      final document = Document.blank()
        ..insert(
          [0],
          [dateMentionNode()],
        );
      final markdown = await customDocumentToMarkdown(document);
      expect(
        markdown,
        '${DateFormat.yMMMd().format(dateTime)}\n',
      );
    });
  });
}
