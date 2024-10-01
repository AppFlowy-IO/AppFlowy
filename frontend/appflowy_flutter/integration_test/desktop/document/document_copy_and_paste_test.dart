import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/block_menu/block_menu_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_preview.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('copy and paste in document', () {
    testWidgets('paste multiple lines at the first line', (tester) async {
      // mock the clipboard
      const lines = 3;
      await tester.pasteContent(
        plainText: List.generate(lines, (index) => 'line $index').join('\n'),
        (editorState) {
          expect(editorState.document.root.children.length, 3);
          for (var i = 0; i < lines; i++) {
            expect(
              editorState.getNodeAtPath([i])!.delta!.toPlainText(),
              'line $i',
            );
          }
        },
      );
    });

    // ## **User Installation**
    // - [Windows/Mac/Linux](https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/mac-windows-linux-packages)
    // - [Docker](https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/installing-with-docker)
    // - [Source](https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/from-source)
    testWidgets('paste content from html, sample 1', (tester) async {
      await tester.pasteContent(
        html:
            '''<meta charset='utf-8'><h2><strong>User Installation</strong></h2>
<ul>
<li><a href="https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/mac-windows-linux-packages">Windows/Mac/Linux</a></li>
<li><a href="https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/installing-with-docker">Docker</a></li>
<li><a href="https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/from-source">Source</a></li>
</ul>''',
        (editorState) {
          expect(editorState.document.root.children.length, 4);
          final node1 = editorState.getNodeAtPath([0])!;
          final node2 = editorState.getNodeAtPath([1])!;
          final node3 = editorState.getNodeAtPath([2])!;
          final node4 = editorState.getNodeAtPath([3])!;
          expect(node1.delta!.toJson(), [
            {
              "insert": "User Installation",
              "attributes": {"bold": true},
            }
          ]);
          expect(node2.delta!.toJson(), [
            {
              "insert": "Windows/Mac/Linux",
              "attributes": {
                "href":
                    "https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/mac-windows-linux-packages",
              },
            }
          ]);
          expect(
            node3.delta!.toJson(),
            [
              {
                "insert": "Docker",
                "attributes": {
                  "href":
                      "https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/installing-with-docker",
                },
              }
            ],
          );
          expect(
            node4.delta!.toJson(),
            [
              {
                "insert": "Source",
                "attributes": {
                  "href":
                      "https://appflowy.gitbook.io/docs/essential-documentation/install-appflowy/installation-methods/from-source",
                },
              }
            ],
          );
        },
      );
    });

    testWidgets('paste code from VSCode', (tester) async {
      await tester.pasteContent(
          html:
              '''<meta charset='utf-8'><div style="color: #bbbbbb;background-color: #262335;font-family: Consolas, 'JetBrains Mono', monospace, 'cascadia code', Menlo, Monaco, 'Courier New', monospace;font-weight: normal;font-size: 14px;line-height: 21px;white-space: pre;"><div><span style="color: #fede5d;">void</span><span style="color: #ff7edb;"> </span><span style="color: #36f9f6;">main</span><span style="color: #ff7edb;">() {</span></div><div><span style="color: #ff7edb;">  </span><span style="color: #36f9f6;">runApp</span><span style="color: #ff7edb;">(</span><span style="color: #fede5d;">const</span><span style="color: #ff7edb;"> </span><span style="color: #fe4450;">MyApp</span><span style="color: #ff7edb;">());</span></div><div><span style="color: #ff7edb;">}</span></div></div>''',
          (editorState) {
        expect(editorState.document.root.children.length, 3);
        final node1 = editorState.getNodeAtPath([0])!;
        final node2 = editorState.getNodeAtPath([1])!;
        final node3 = editorState.getNodeAtPath([2])!;
        expect(node1.type, ParagraphBlockKeys.type);
        expect(node2.type, ParagraphBlockKeys.type);
        expect(node3.type, ParagraphBlockKeys.type);
        expect(node1.delta!.toJson(), [
          {'insert': 'void main() {'},
        ]);
        expect(node2.delta!.toJson(), [
          {'insert': "  runApp(const MyApp());"},
        ]);
        expect(node3.delta!.toJson(), [
          {"insert": "}"},
        ]);
      });
    });

    testWidgets('paste bulleted list in numbered list', (tester) async {
      const inAppJson =
          '{"document":{"type":"page","children":[{"type":"bulleted_list","children":[{"type":"bulleted_list","data":{"delta":[{"insert":"World"}]}}],"data":{"delta":[{"insert":"Hello"}]}}]}}';

      await tester.pasteContent(
        inAppJson: inAppJson,
        beforeTest: (editorState) async {
          final transaction = editorState.transaction;
          // Insert two numbered list nodes
          // 1. Parent One
          // 2.
          transaction.insertNodes(
            [0],
            [
              Node(
                type: NumberedListBlockKeys.type,
                attributes: {
                  'delta': [
                    {"insert": "One"},
                  ],
                },
              ),
              Node(
                type: NumberedListBlockKeys.type,
                attributes: {'delta': []},
              ),
            ],
          );

          // Set the selection to the second numbered list node (which has empty delta)
          transaction.afterSelection = Selection.collapsed(Position(path: [1]));

          await editorState.apply(transaction);
          await tester.pumpAndSettle();
        },
        (editorState) {
          final secondNode = editorState.getNodeAtPath([1]);
          expect(secondNode?.delta?.toPlainText(), 'Hello');
          expect(secondNode?.children.length, 1);

          final childNode = secondNode?.children.first;
          expect(childNode?.delta?.toPlainText(), 'World');
          expect(childNode?.type, BulletedListBlockKeys.type);
        },
      );
    });
  });

  testWidgets('paste text on part of bullet list', (tester) async {
    const plainText = 'test';

    await tester.pasteContent(
      plainText: plainText,
      beforeTest: (editorState) async {
        final transaction = editorState.transaction;
        transaction.insertNodes(
          [0],
          [
            Node(
              type: BulletedListBlockKeys.type,
              attributes: {
                'delta': [
                  {"insert": "bullet list"},
                ],
              },
            ),
          ],
        );

        // Set the selection to the second numbered list node (which has empty delta)
        transaction.afterSelection = Selection(
          start: Position(path: [0], offset: 7),
          end: Position(path: [0], offset: 11),
        );

        await editorState.apply(transaction);
        await tester.pumpAndSettle();
      },
      (editorState) {
        final node = editorState.getNodeAtPath([0]);
        expect(node?.delta?.toPlainText(), 'bullet test');
        expect(node?.type, BulletedListBlockKeys.type);
      },
    );
  });

  testWidgets('paste image(png) from memory', (tester) async {
    final image = await rootBundle.load('assets/test/images/sample.png');
    final bytes = image.buffer.asUint8List();
    await tester.pasteContent(image: ('png', bytes), (editorState) {
      expect(editorState.document.root.children.length, 1);
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], isNotNull);
    });
  });

  testWidgets('paste image(jpeg) from memory', (tester) async {
    final image = await rootBundle.load('assets/test/images/sample.jpeg');
    final bytes = image.buffer.asUint8List();
    await tester.pasteContent(image: ('jpeg', bytes), (editorState) {
      expect(editorState.document.root.children.length, 1);
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], isNotNull);
    });
  });

  testWidgets('paste image(gif) from memory', (tester) async {
    final image = await rootBundle.load('assets/test/images/sample.gif');
    final bytes = image.buffer.asUint8List();
    await tester.pasteContent(image: ('gif', bytes), (editorState) {
      expect(editorState.document.root.children.length, 1);
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], isNotNull);
    });
  });

  testWidgets(
    'format the selected text to href when pasting url if available',
    (tester) async {
      const text = 'appflowy';
      const url = 'https://appflowy.io';
      await tester.pasteContent(
        plainText: url,
        beforeTest: (editorState) async {
          await tester.ime.insertText(text);
          await tester.editor.updateSelection(
            Selection.single(
              path: [0],
              startOffset: 0,
              endOffset: text.length,
            ),
          );
        },
        (editorState) {
          final node = editorState.getNodeAtPath([0])!;
          expect(node.type, ParagraphBlockKeys.type);
          expect(node.delta!.toJson(), [
            {
              'insert': text,
              'attributes': {'href': url},
            }
          ]);
        },
      );
    },
  );

  // https://github.com/AppFlowy-IO/AppFlowy/issues/3263
  testWidgets(
    'paste the image from clipboard when html and image are both available',
    (tester) async {
      const html =
          '''<meta charset='utf-8'><img src="https://user-images.githubusercontent.com/9403740/262918875-603f4adb-58dd-49b5-8201-341d354935fd.png" alt="image"/>''';
      final image = await rootBundle.load('assets/test/images/sample.png');
      final bytes = image.buffer.asUint8List();
      await tester.pasteContent(
        html: html,
        image: ('png', bytes),
        (editorState) {
          expect(editorState.document.root.children.length, 1);
          final node = editorState.getNodeAtPath([0])!;
          expect(node.type, ImageBlockKeys.type);
        },
      );
    },
  );

  testWidgets('paste the html content contains section', (tester) async {
    const html =
        '''<meta charset='utf-8'><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;">AppFlowy</strong></span></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;">Hello World</strong></span></section>''';
    await tester.pasteContent(html: html, (editorState) {
      expect(editorState.document.root.children.length, 2);
      final node1 = editorState.getNodeAtPath([0])!;
      final node2 = editorState.getNodeAtPath([1])!;
      expect(node1.type, ParagraphBlockKeys.type);
      expect(node2.type, ParagraphBlockKeys.type);
    });
  });

  testWidgets('paste the html from google translation', (tester) async {
    const html =
        '''<meta charset='utf-8'><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">new force</font></font></strong></span></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">Assessment focus: potential motivations, empathy</font></font></strong></span></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><br style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important;"></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">➢Personality characteristics and potential motivations:</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Reflection of self-worth</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Need to be respected</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Have a unique definition of success</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Be true to your own lifestyle</font></font></section>''';
    await tester.pasteContent(html: html, (editorState) {
      expect(editorState.document.root.children.length, 8);
    });
  });

  testWidgets(
    'auto convert url to link preview block',
    (tester) async {
      const url = 'https://appflowy.io';
      await tester.pasteContent(plainText: url, (editorState) async {
        // the second one is the paragraph node
        expect(editorState.document.root.children.length, 2);
        final node = editorState.getNodeAtPath([0])!;
        expect(node.type, LinkPreviewBlockKeys.type);
        expect(node.attributes[LinkPreviewBlockKeys.url], url);
      });

      // hover on the link preview block
      // click the more button
      // and select convert to link
      await tester.hoverOnWidget(
        find.byType(CustomLinkPreviewWidget),
        onHover: () async {
          final convertToLinkButton = find.byWidgetPredicate((widget) {
            return widget is MenuBlockButton &&
                widget.tooltip ==
                    LocaleKeys.document_plugins_urlPreview_convertToLink.tr();
          });
          expect(convertToLinkButton, findsOneWidget);
          await tester.tap(convertToLinkButton);
          await tester.pumpAndSettle();
        },
      );

      await tester.pumpAndSettle();

      final editorState = tester.editor.getCurrentEditorState();
      final textNode = editorState.getNodeAtPath([0])!;
      expect(textNode.type, ParagraphBlockKeys.type);
      expect(textNode.delta!.toJson(), [
        {
          'insert': url,
          'attributes': {'href': url},
        }
      ]);
    },
  );

  testWidgets(
    'ctrl/cmd+z to undo the auto convert url to link preview block',
    (tester) async {
      const url = 'https://appflowy.io';
      await tester.pasteContent(plainText: url, (editorState) async {
        // the second one is the paragraph node
        expect(editorState.document.root.children.length, 2);
        final node = editorState.getNodeAtPath([0])!;
        expect(node.type, LinkPreviewBlockKeys.type);
        expect(node.attributes[LinkPreviewBlockKeys.url], url);
      });

      await tester.editor.tapLineOfEditorAt(0);
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed:
            UniversalPlatform.isLinux || UniversalPlatform.isWindows,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      final editorState = tester.editor.getCurrentEditorState();
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ParagraphBlockKeys.type);
      expect(node.delta!.toJson(), [
        {
          'insert': url,
          'attributes': {'href': url},
        }
      ]);
    },
  );

  testWidgets(
    'ctrl/cmd+z to undo the auto convert url to link preview block',
    (tester) async {
      const text = 'Hello World';
      final editorState = tester.editor.getCurrentEditorState();
      final transaction = editorState.transaction;
      // [image_block]
      // [paragraph_block]
      transaction.insertNodes([
        0,
      ], [
        customImageNode(url: ''),
        paragraphNode(text: text),
      ]);
      await editorState.apply(transaction);

      await tester.editor.tapLineOfEditorAt(0);
      // select all
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyA,
        isControlPressed:
            UniversalPlatform.isLinux || UniversalPlatform.isWindows,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // put the cursor to the end of the paragraph block
      await editorState.updateSelectionWithReason(
        Selection.collapsed(Position(path: [1], offset: text.length)),
        reason: SelectionUpdateReason.uiEvent,
      );

      // paste the content
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed:
            UniversalPlatform.isLinux || UniversalPlatform.isWindows,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // expect the image and the paragraph block are inserted below the cursor
      expect(editorState.document.root.children.length, 4);
      expect(editorState.getNodeAtPath([0])!.type, CustomImageBlockKeys.type);
      expect(editorState.getNodeAtPath([1])!.type, ParagraphBlockKeys.type);
      expect(editorState.getNodeAtPath([2])!.type, CustomImageBlockKeys.type);
      expect(editorState.getNodeAtPath([3])!.type, ParagraphBlockKeys.type);
    },
  );

  testWidgets('paste the url without protocol', (tester) async {
    // paste the image that from local file
    const plainText = '1.jpg';
    final image = await rootBundle.load('assets/test/images/sample.jpeg');
    final bytes = image.buffer.asUint8List();
    await tester.pasteContent(plainText: plainText, image: ('jpeg', bytes),
        (editorState) {
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], isNotEmpty);
    });
  });

  testWidgets('paste the image url', (tester) async {
    const plainText = 'https://appflowy.io/1.jpg';
    final image = await rootBundle.load('assets/test/images/sample.jpeg');
    final bytes = image.buffer.asUint8List();
    await tester.pasteContent(plainText: plainText, image: ('jpeg', bytes),
        (editorState) {
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], isNotEmpty);
    });
  });
}

extension on WidgetTester {
  Future<void> pasteContent(
    void Function(EditorState editorState) test, {
    Future<void> Function(EditorState editorState)? beforeTest,
    String? plainText,
    String? html,
    String? inAppJson,
    (String, Uint8List?)? image,
  }) async {
    await initializeAppFlowy();
    await tapAnonymousSignInButton();

    // create a new document
    await createNewPageWithNameUnderParent(name: 'Test Document');
    // tap the editor
    await tapButton(find.byType(AppFlowyEditor));

    await beforeTest?.call(editor.getCurrentEditorState());

    // mock the clipboard
    await getIt<ClipboardService>().setData(
      ClipboardServiceData(
        plainText: plainText,
        html: html,
        inAppJson: inAppJson,
        image: image,
      ),
    );

    // paste the text
    await simulateKeyEvent(
      LogicalKeyboardKey.keyV,
      isControlPressed: Platform.isLinux || Platform.isWindows,
      isMetaPressed: Platform.isMacOS,
    );
    await pumpAndSettle();

    test(editor.getCurrentEditorState());
  }
}
