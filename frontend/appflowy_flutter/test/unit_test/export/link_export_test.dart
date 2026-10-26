import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/custom_copy_command.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/shared/mention_block_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/application/export/document_link_resolver.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestClipboardService extends ClipboardService {
  ClipboardServiceData? lastData;

  @override
  Future<void> setData(ClipboardServiceData data) async {
    lastData = data;
  }
}

void main() {
  group('Issue 9041 - Preserve links on export', () {
    const url = 'https://appflowy.com/';
    late _TestClipboardService testClipboard;

    setUpAll(() {
      testClipboard = _TestClipboardService();
      if (getIt.isRegistered<ClipboardService>()) {
        getIt.unregister<ClipboardService>();
      }
      getIt.registerSingleton<ClipboardService>(testClipboard);
    });

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
        final html = exportDocumentToHTML(document);

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

    test('Production clipboard copy (handleCopyCommand) preserves URLs and HTML links', () async {
      final document = createTestDocument();
      final editorState = EditorState(document: document);
      editorState.selection = Selection(
        start: const Position(path: [0], offset: 0),
        end: Position(
          path: [document.root.children.length - 1],
          offset: document.root.children.last.delta?.length ?? 0,
        ),
      );

      final result = handleCopyCommand(editorState);
      expect(result, equals(KeyEventResult.handled));

      // Allow async clipboard write to settle
      await Future.delayed(Duration.zero);

      expect(testClipboard.lastData, isNotNull);
      final plainText = testClipboard.lastData!.plainText!;
      final html = testClipboard.lastData!.html!;

      expect(plainText.contains(r'$'), isFalse);
      expect(plainText, equals('$url\n$url\n$url\n$url\n$url\n$url'));

      expect(html.contains(r'$'), isFalse);
      expect(html.contains('<null>'), isFalse);
      expect(html.contains('href="$url"'), isTrue);
    });

    test('Preserves document root ID for stable export archive names', () {
      final document = createTestDocument();
      final originalId = document.root.id;
      final resolvedDoc = resolveDocumentLinksForExport(document);
      expect(resolvedDoc.root.id, equals(originalId));
    });

    test('Unsafe schemes (e.g. javascript:) are exported as plain text, not active links', () async {
      const unsafeUrl = 'javascript:alert(1)';
      final document = Document.blank()
        ..insert(
          [0],
          [
            paragraphNode(
              delta: Delta()
                ..insert(
                  MentionBlockKeys.mentionChar,
                  attributes: {
                    MentionBlockKeys.mention: {
                      MentionBlockKeys.type: MentionType.externalLink.name,
                      MentionBlockKeys.url: unsafeUrl,
                    },
                  },
                ),
            ),
            Node(
              type: LinkPreviewBlockKeys.type,
              attributes: {LinkPreviewBlockKeys.url: unsafeUrl},
            ),
          ],
        );

      // Markdown export renders plain text rather than active markdown link
      final markdown = await customDocumentToMarkdown(document);
      expect(markdown.contains(']($unsafeUrl)'), isFalse);
      expect(markdown, equals('$unsafeUrl\n$unsafeUrl\n'));

      // HTML export renders plain paragraph rather than active anchor
      final html = exportDocumentToHTML(document);
      expect(html.contains('href'), isFalse);
      expect(html, equals('<p>$unsafeUrl</p><p>$unsafeUrl</p>'));
    });

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

      final html = exportDocumentToHTML(document);
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

      final html = exportDocumentToHTML(document);
      expect(html, '<div><input type="checkbox"><a href="$url">$url</a></div>');
    });
  });
}
