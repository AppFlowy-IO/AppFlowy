import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
          {
            "insert": "void",
            "attributes": {"font_color": "0xfffede5d"},
          },
          {
            "insert": " ",
            "attributes": {"font_color": "0xffff7edb"},
          },
          {
            "insert": "main",
            "attributes": {"font_color": "0xff36f9f6"},
          },
          {
            "insert": "() {",
            "attributes": {"font_color": "0xffff7edb"},
          }
        ]);
        expect(node2.delta!.toJson(), [
          {
            "insert": "  ",
            "attributes": {"font_color": "0xffff7edb"},
          },
          {
            "insert": "runApp",
            "attributes": {"font_color": "0xff36f9f6"},
          },
          {
            "insert": "(",
            "attributes": {"font_color": "0xffff7edb"},
          },
          {
            "insert": "const",
            "attributes": {"font_color": "0xfffede5d"},
          },
          {
            "insert": " ",
            "attributes": {"font_color": "0xffff7edb"},
          },
          {
            "insert": "MyApp",
            "attributes": {"font_color": "0xfffe4450"},
          },
          {
            "insert": "());",
            "attributes": {"font_color": "0xffff7edb"},
          }
        ]);
        expect(node3.delta!.toJson(), [
          {
            "insert": "}",
            "attributes": {"font_color": "0xffff7edb"},
          }
        ]);
      });
    });
  });

  testWidgets('paste image(png) from memory', (tester) async {
    final image = await rootBundle.load('assets/test/images/sample.png');
    final bytes = image.buffer.asUint8List();
    await tester.pasteContent(image: ('png', bytes), (editorState) {
      expect(editorState.document.root.children.length, 2);
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], isNotNull);
    });
  });

  testWidgets('paste image(jpeg) from memory', (tester) async {
    final image = await rootBundle.load('assets/test/images/sample.jpeg');
    final bytes = image.buffer.asUint8List();
    await tester.pasteContent(image: ('jpeg', bytes), (editorState) {
      expect(editorState.document.root.children.length, 2);
      final node = editorState.getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], isNotNull);
    });
  });

  testWidgets('paste image(gif) from memory', (tester) async {
    // It's not supported yet.
    // final image = await rootBundle.load('assets/test/images/sample.gif');
    // final bytes = image.buffer.asUint8List();
    // await tester.pasteContent(image: ('gif', bytes), (editorState) {
    //   expect(editorState.document.root.children.length, 2);
    //   final node = editorState.getNodeAtPath([0])!;
    //   expect(node.type, ImageBlockKeys.type);
    //   expect(node.attributes[ImageBlockKeys.url], isNotNull);
    // });
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
          expect(editorState.document.root.children.length, 2);
          final node = editorState.getNodeAtPath([0])!;
          expect(node.type, ImageBlockKeys.type);
          expect(
            node.attributes[ImageBlockKeys.url],
            'https://user-images.githubusercontent.com/9403740/262918875-603f4adb-58dd-49b5-8201-341d354935fd.png',
          );
        },
      );
    },
  );

  testWidgets('paste the html content contains section', (tester) async {
    const html =
        '''<meta charset='utf-8'><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;">AppFlowy</strong></span></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;">Hello World</strong></span></section>''';
    await tester.pasteContent(
      html: html,
      (editorState) {
        expect(editorState.document.root.children.length, 2);
        final node1 = editorState.getNodeAtPath([0])!;
        final node2 = editorState.getNodeAtPath([1])!;
        expect(node1.type, ParagraphBlockKeys.type);
        expect(node2.type, ParagraphBlockKeys.type);
      },
    );
  });

  testWidgets('paste the html from google translation', (tester) async {
    const html =
        '''<meta charset='utf-8'><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">new force</font></font></strong></span></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgb(0, 160, 113);"><strong style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">Assessment focus: potential motivations, empathy</font></font></strong></span></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><br style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important;"></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">➢Personality characteristics and potential motivations:</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Reflection of self-worth</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Need to be respected</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Have a unique definition of success</font></font></section><section style="margin: 0px 8px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box; overflow-wrap: break-word !important; color: rgba(255, 255, 255, 0.6); font-family: system-ui, -apple-system, &quot;system-ui&quot;, &quot;Helvetica Neue&quot;, &quot;PingFang SC&quot;, &quot;Hiragino Sans GB&quot;, &quot;Microsoft YaHei UI&quot;, &quot;Microsoft YaHei&quot;, Arial, sans-serif; font-size: 15px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: 0.544px; orphans: 2; text-align: justify; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(25, 25, 25); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;"><font style="margin: 0px; padding: 0px; outline: 0px; max-width: 100%; box-sizing: border-box !important; overflow-wrap: break-word !important; vertical-align: inherit;">-Be true to your own lifestyle</font></font></section>''';
    await tester.pasteContent(
      html: html,
      (editorState) {
        expect(editorState.document.root.children.length, 8);
      },
    );
  });

  testWidgets(
    'auto convert url to link preview block',
    (widgetTester) async {
      const url = 'https://appflowy.io';
      await widgetTester.pasteContent(
        plainText: url,
        (editorState) {
          expect(editorState.document.root.children.length, 2);
          final node = editorState.getNodeAtPath([0])!;
          expect(node.type, LinkPreviewBlockKeys.type);
          expect(node.attributes[LinkPreviewBlockKeys.url], url);
        },
      );
    },
  );
}

extension on WidgetTester {
  Future<void> pasteContent(
    void Function(EditorState editorState) test, {
    Future<void> Function(EditorState editorState)? beforeTest,
    String? plainText,
    String? html,
    (String, Uint8List?)? image,
  }) async {
    await initializeAppFlowy();
    await tapGoButton();

    // create a new document
    await createNewPageWithNameUnderParent();

    await beforeTest?.call(editor.getCurrentEditorState());

    // mock the clipboard
    await getIt<ClipboardService>().setData(
      ClipboardServiceData(
        plainText: plainText,
        html: html,
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
