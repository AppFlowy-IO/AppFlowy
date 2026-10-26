import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/link_preview_node_parser.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/workspace/application/export/document_link_resolver.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 9041 - Preserve links on export', () {
    const url = 'https://appflowy.com/';

    Document createTestDocument() {
      // 1. Mention
      final mentionNode = paragraphNode(
        delta: Delta()
          ..insert(
            MentionBlockKeys.mentionChar,
            attributes: {
              MentionBlockKeys.mention: {
                MentionBlockKeys.type: MentionType.externalLink.name,
                MentionBlockKeys.url: url,
              },
            },
          ),
      );

      // 2. Ordinary link
      final urlNode = paragraphNode(
        delta: Delta()
          ..insert(url, attributes: {AppFlowyRichTextKeys.href: url}),
      );

      // 3. Bookmark
      final bookmarkNode = Node(
        type: LinkPreviewBlockKeys.type,
        attributes: {LinkPreviewBlockKeys.url: url},
      );

      // 4. Embed
      final embedNode = Node(
        type: LinkPreviewBlockKeys.type,
        attributes: {
          LinkPreviewBlockKeys.url: url,
          LinkEmbedKeys.previewType: LinkEmbedKeys.embed,
        },
      );

      // 5. Mention inside checkbox
      final checkboxMentionNode = todoListNode(
        checked: false,
        delta: Delta()
          ..insert(
            MentionBlockKeys.mentionChar,
            attributes: {
              MentionBlockKeys.mention: {
                MentionBlockKeys.type: MentionType.externalLink.name,
                MentionBlockKeys.url: url,
              },
            },
          ),
      );

      // 6. Ordinary link inside checkbox
      final checkboxUrlNode = todoListNode(
        checked: false,
        delta: Delta()
          ..insert(url, attributes: {AppFlowyRichTextKeys.href: url}),
      );

      return Document.blank()..insert(
        [0],
        [
          mentionNode,
          urlNode,
          bookmarkNode,
          embedNode,
          checkboxMentionNode,
          checkboxUrlNode,
        ],
      );
    }

    test('Markdown export preserves all links without emitting \$', () async {
      final document = createTestDocument();
      final markdown = await customDocumentToMarkdown(document);

      expect(markdown.contains(r'$'), isFalse);
      expect(
        markdown,
        equals(
          '[$url]($url)\n'
          '[$url]($url)\n'
          '[$url]($url)\n'
          '[$url]($url)\n'
          '- [ ] [$url]($url)\n'
          '- [ ] [$url]($url)\n',
        ),
      );
    });

    test(
      'HTML export preserves all links without emitting <null>\$</null>',
      () {
        final document = createTestDocument();
        final resolvedDoc = resolveDocumentLinksForExport(document);
        final html = documentToHTML(
          resolvedDoc,
          customParsers: [const HTMLLinkPreviewNodeParser()],
        );

        expect(html.contains(r'$'), isFalse);
        expect(html.contains('<null>'), isFalse);
        expect(
          html,
          equals(
            '<p><a href="$url">$url</a></p>'
            '<p><a href="$url">$url</a></p>'
            '<p><a href="$url">$url</a></p>'
            '<p><a href="$url">$url</a></p>'
            '<div><input type="checkbox"><a href="$url">$url</a></div>'
            '<div><input type="checkbox"><a href="$url">$url</a></div>',
          ),
        );
      },
    );

    test(
      'Plain text / clipboard export preserves all URLs without emitting \$',
      () {
        final document = createTestDocument();
        final resolvedDoc = resolveDocumentLinksForExport(document);
        final plainTexts = resolvedDoc.root.children
            .map((n) => n.delta?.toPlainText() ?? '')
            .where((s) => s.isNotEmpty)
            .join('\n');

        expect(plainTexts.contains(r'$'), isFalse);
        expect(plainTexts, equals('$url\n$url\n$url\n$url\n$url\n$url'));
      },
    );

    test('Preserves surrounding text with mentions', () async {
      final document = Document.blank()
        ..insert(
          [0],
          [
            paragraphNode(
              delta: Delta()
                ..insert('Check out ')
                ..insert(
                  MentionBlockKeys.mentionChar,
                  attributes: {
                    MentionBlockKeys.mention: {
                      MentionBlockKeys.type: MentionType.externalLink.name,
                      MentionBlockKeys.url: url,
                    },
                  },
                )
                ..insert(' for more details!'),
            ),
          ],
        );

      final markdown = await customDocumentToMarkdown(document);
      expect(markdown, 'Check out [$url]($url) for more details!\n');

      final resolvedDoc = resolveDocumentLinksForExport(document);
      final html = documentToHTML(
        resolvedDoc,
        customParsers: [const HTMLLinkPreviewNodeParser()],
      );
      expect(
        html,
        '<p>Check out <a href="$url">$url</a> for more details!</p>',
      );
    });

    test('Bookmark converted to checkbox preserves link structure', () async {
      final bookmarkCheckbox = todoListNode(checked: false, delta: Delta())
        ..updateAttributes({LinkPreviewBlockKeys.url: url});

      final document = Document.blank()..insert([0], [bookmarkCheckbox]);
      final markdown = await customDocumentToMarkdown(document);
      expect(markdown, '- [ ] [$url]($url)\n');

      final resolvedDoc = resolveDocumentLinksForExport(document);
      final html = documentToHTML(
        resolvedDoc,
        customParsers: [const HTMLLinkPreviewNodeParser()],
      );
      expect(html, '<div><input type="checkbox"><a href="$url">$url</a></div>');
    });
  });
}
