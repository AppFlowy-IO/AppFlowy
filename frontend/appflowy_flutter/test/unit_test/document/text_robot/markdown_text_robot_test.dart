import 'package:appflowy/plugins/document/presentation/editor_plugins/base/markdown_text_robot.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('markdown text robot:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    Future<void> testLiveRefresh(
      List<String> texts, {
      required void Function(EditorState) expect,
    }) async {
      final editorState = EditorState.blank();
      editorState.selection = Selection.collapsed(Position(path: [0]));
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      markdownTextRobot.start();
      for (final text in texts) {
        await markdownTextRobot.appendMarkdownText(text);
        // mock the delay of the text robot
        await Future.delayed(const Duration(milliseconds: 10));
      }
      await markdownTextRobot.persist();

      expect(editorState);
    }

    test('parse markdown text (1)', () async {
      final editorState = EditorState.blank();
      editorState.selection = Selection.collapsed(Position(path: [0]));
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );

      markdownTextRobot.start();
      await markdownTextRobot.appendMarkdownText(_sample1);
      await markdownTextRobot.persist();

      final nodes = editorState.document.root.children;
      expect(nodes.length, 4);

      final n1 = nodes[0];
      expect(n1.delta!.toPlainText(), 'The Curious Cat');
      expect(n1.type, HeadingBlockKeys.type);

      final n2 = nodes[1];
      expect(n2.type, ParagraphBlockKeys.type);
      expect(n2.delta!.toJson(), [
        {'insert': 'Once upon a time in a '},
        {
          'insert': 'quiet village',
          'attributes': {'bold': true},
        },
        {'insert': ', there lived a curious cat named '},
        {
          'insert': 'Whiskers',
          'attributes': {'italic': true},
        },
        {'insert': '. Unlike other cats, Whiskers had a passion for '},
        {
          'insert': 'exploration',
          'attributes': {'bold': true},
        },
        {
          'insert':
              '. Every day, he\'d wander through the village, discovering hidden spots and making new friends with the local animals.',
        },
      ]);

      final n3 = nodes[2];
      expect(n3.type, ParagraphBlockKeys.type);
      expect(n3.delta!.toJson(), [
        {'insert': 'One sunny morning, Whiskers stumbled upon a mysterious '},
        {
          'insert': 'wooden box',
          'attributes': {'bold': true},
        },
        {'insert': ' behind the old barn. It was covered in '},
        {
          'insert': 'vines and dust',
          'attributes': {'italic': true},
        },
        {
          'insert':
              '. Intrigued, he nudged it open with his paw and found a collection of ancient maps. These maps led to secret trails around the village.',
        },
      ]);

      final n4 = nodes[3];
      expect(n4.type, ParagraphBlockKeys.type);
      expect(n4.delta!.toJson(), [
        {
          'insert':
              'Whiskers became the village\'s hero, guiding everyone on exciting adventures.',
        },
      ]);
    });

    // Live refresh - Partial sample
    // ## The Decision
    // - Aria found an ancient map in her grandmother's attic.
    // - The map hinted at a mystical place known as the Enchanted Forest.
    // - Legends spoke of the forest as a realm where dreams came to life.
    test('live refresh (2)', () async {
      await testLiveRefresh(
        _liveRefreshSample2,
        expect: (editorState) {
          final nodes = editorState.document.root.children;
          expect(nodes.length, 4);

          final n1 = nodes[0];
          expect(n1.type, HeadingBlockKeys.type);
          expect(n1.delta!.toPlainText(), 'The Decision');

          final n2 = nodes[1];
          expect(n2.type, BulletedListBlockKeys.type);
          expect(
            n2.delta!.toPlainText(),
            'Aria found an ancient map in her grandmother\'s attic.',
          );

          final n3 = nodes[2];
          expect(n3.type, BulletedListBlockKeys.type);
          expect(
            n3.delta!.toPlainText(),
            'The map hinted at a mystical place known as the Enchanted Forest.',
          );

          final n4 = nodes[3];
          expect(n4.type, BulletedListBlockKeys.type);
          expect(
            n4.delta!.toPlainText(),
            'Legends spoke of the forest as a realm where dreams came to life.',
          );
        },
      );
    });

    // Partial sample
    // ## The Preparation
    // Before embarking on her journey, Aria prepared meticulously:
    // 1. Gather Supplies
    //   - A sturdy backpack
    //   - A compass and a map
    //   - Provisions for the week
    // 2. Seek Guidance
    //   - Visited the village elder for advice
    //   - Listened to tales of past adventurers
    // 3. Sharpen Skills
    //   - Practiced archery and swordsmanship
    //   - Enhanced survival skills
    test('live refresh (3)', () async {
      await testLiveRefresh(
        _liveRefreshSample3,
        expect: (editorState) {
          final nodes = editorState.document.root.children;
          expect(nodes.length, 5);

          final n1 = nodes[0];
          expect(n1.type, HeadingBlockKeys.type);
          expect(n1.delta!.toPlainText(), 'The Preparation');

          final n2 = nodes[1];
          expect(n2.type, ParagraphBlockKeys.type);
          expect(
            n2.delta!.toPlainText(),
            'Before embarking on her journey, Aria prepared meticulously:',
          );

          final n3 = nodes[2];
          expect(n3.type, NumberedListBlockKeys.type);
          expect(
            n3.delta!.toPlainText(),
            'Gather Supplies',
          );

          final n3c1 = n3.children[0];
          expect(n3c1.type, BulletedListBlockKeys.type);
          expect(n3c1.delta!.toPlainText(), 'A sturdy backpack');

          final n3c2 = n3.children[1];
          expect(n3c2.type, BulletedListBlockKeys.type);
          expect(n3c2.delta!.toPlainText(), 'A compass and a map');

          final n3c3 = n3.children[2];
          expect(n3c3.type, BulletedListBlockKeys.type);
          expect(n3c3.delta!.toPlainText(), 'Provisions for the week');

          final n4 = nodes[3];
          expect(n4.type, NumberedListBlockKeys.type);
          expect(n4.delta!.toPlainText(), 'Seek Guidance');

          final n4c1 = n4.children[0];
          expect(n4c1.type, BulletedListBlockKeys.type);
          expect(
            n4c1.delta!.toPlainText(),
            'Visited the village elder for advice',
          );

          final n4c2 = n4.children[1];
          expect(n4c2.type, BulletedListBlockKeys.type);
          expect(
            n4c2.delta!.toPlainText(),
            'Listened to tales of past adventurers',
          );

          final n5 = nodes[4];
          expect(n5.type, NumberedListBlockKeys.type);
          expect(
            n5.delta!.toPlainText(),
            'Sharpen Skills',
          );

          final n5c1 = n5.children[0];
          expect(n5c1.type, BulletedListBlockKeys.type);
          expect(
            n5c1.delta!.toPlainText(),
            'Practiced archery and swordsmanship',
          );

          final n5c2 = n5.children[1];
          expect(n5c2.type, BulletedListBlockKeys.type);
          expect(
            n5c2.delta!.toPlainText(),
            'Enhanced survival skills',
          );
        },
      );
    });

    // Partial sample
    // Sure, let's provide an alternative Rust implementation for the Two Sum problem, focusing on clarity and efficiency but with a slightly different approach:
    // ```rust
    // fn two_sum(nums: &[i32], target: i32) -> Vec<(usize, usize)> {
    //     let mut results = Vec::new();
    //     let mut map = std::collections::HashMap::new();
    //
    //     for (i, &num) in nums.iter().enumerate() {
    //         let complement = target - num;
    //         if let Some(&j) = map.get(&complement) {
    //             results.push((j, i));
    //         }
    //         map.insert(num, i);
    //     }
    //
    //     results
    // }
    //
    // fn main() {
    //     let nums = vec![2, 7, 11, 15];
    //     let target = 9;
    //
    //     let pairs = two_sum(&nums, target);
    //     if pairs.is_empty() {
    //         println!("No two sum solution found");
    //     } else {
    //         for (i, j) in pairs {
    //             println!("Indices: {}, {}", i, j);
    //         }
    //     }
    // }
    // ```
    test('live refresh (4)', () async {
      await testLiveRefresh(
        _liveRefreshSample4,
        expect: (editorState) {
          final nodes = editorState.document.root.children;
          expect(nodes.length, 2);

          final n1 = nodes[0];
          expect(n1.type, ParagraphBlockKeys.type);
          expect(
            n1.delta!.toPlainText(),
            '''Sure, let's provide an alternative Rust implementation for the Two Sum problem, focusing on clarity and efficiency but with a slightly different approach:''',
          );

          final n2 = nodes[1];
          expect(n2.type, CodeBlockKeys.type);
          expect(
            n2.delta!.toPlainText(),
            isNotEmpty,
          );
          expect(n2.attributes[CodeBlockKeys.language], 'rust');
        },
      );
    });
  });

  group('markdown text robot - replace in same line:', () {
    final text1 =
        '''The introduction of the World Wide Web in the early 1990s marked a turning point. ''';
    final text2 =
        '''Tim Berners-Lee's invention made the internet accessible to non-technical users, opening the floodgates for mass adoption. ''';
    final text3 =
        '''Email became widespread, and instant messaging services like ICQ and AOL Instant Messenger gained popularity, allowing for real-time text communication.''';

    Document buildTestDocument() {
      return Document(
        root: pageNode(
          children: [
            paragraphNode(delta: Delta()..insert(text1 + text2 + text3)),
          ],
        ),
      );
    }

    // 1. create a document with a paragraph node
    // 2. use the text robot to replace the selected content in the same line
    // 3. check the document
    test('the selection is in the middle of the text', () async {
      final document = buildTestDocument();
      final editorState = EditorState(document: document);

      editorState.selection = Selection(
        start: Position(
          path: [0],
          offset: text1.length,
        ),
        end: Position(
          path: [0],
          offset: text1.length + text2.length,
        ),
      );

      final markdownText =
          '''Tim Berners-Lee's invention of the **World Wide Web** transformed the internet, making it accessible to _non-technical users_ and opening the floodgates for global mass adoption.''';
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      await markdownTextRobot.replace(
        selection: editorState.selection!,
        markdownText: markdownText,
      );

      final afterDelta = editorState.document.root.children[0].delta!.toList();
      expect(afterDelta.length, 5);

      final d1 = afterDelta[0] as TextInsert;
      expect(d1.text, '${text1}Tim Berners-Lee\'s invention of the ');
      expect(d1.attributes, null);

      final d2 = afterDelta[1] as TextInsert;
      expect(d2.text, 'World Wide Web');
      expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

      final d3 = afterDelta[2] as TextInsert;
      expect(d3.text, ' transformed the internet, making it accessible to ');
      expect(d3.attributes, null);

      final d4 = afterDelta[3] as TextInsert;
      expect(d4.text, 'non-technical users');
      expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

      final d5 = afterDelta[4] as TextInsert;
      expect(
        d5.text,
        ' and opening the floodgates for global mass adoption.$text3',
      );
      expect(d5.attributes, null);
    });

    test('replace markdown text with selection from start to middle', () async {
      final document = buildTestDocument();
      final editorState = EditorState(document: document);

      editorState.selection = Selection(
        start: Position(
          path: [0],
        ),
        end: Position(
          path: [0],
          offset: text1.length,
        ),
      );

      final markdownText =
          '''The **invention** of the _World Wide Web_ by Tim Berners-Lee transformed how we access information.''';
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      await markdownTextRobot.replace(
        selection: editorState.selection!,
        markdownText: markdownText,
      );

      final afterDelta = editorState.document.root.children[0].delta!.toList();
      expect(afterDelta.length, 5);

      final d1 = afterDelta[0] as TextInsert;
      expect(d1.text, 'The ');
      expect(d1.attributes, null);

      final d2 = afterDelta[1] as TextInsert;
      expect(d2.text, 'invention');
      expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

      final d3 = afterDelta[2] as TextInsert;
      expect(d3.text, ' of the ');
      expect(d3.attributes, null);

      final d4 = afterDelta[3] as TextInsert;
      expect(d4.text, 'World Wide Web');
      expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

      final d5 = afterDelta[4] as TextInsert;
      expect(
        d5.text,
        ' by Tim Berners-Lee transformed how we access information.$text2$text3',
      );
      expect(d5.attributes, null);
    });

    test('replace markdown text with selection from middle to end', () async {
      final document = buildTestDocument();
      final editorState = EditorState(document: document);

      editorState.selection = Selection(
        start: Position(
          path: [0],
          offset: text1.length + text2.length,
        ),
        end: Position(
          path: [0],
          offset: text1.length + text2.length + text3.length,
        ),
      );

      final markdownText =
          '''**Email** became widespread, and instant messaging services like *ICQ* and **AOL Instant Messenger** gained tremendous popularity, allowing for seamless real-time text communication across the globe.''';
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      await markdownTextRobot.replace(
        selection: editorState.selection!,
        markdownText: markdownText,
      );

      final afterDelta = editorState.document.root.children[0].delta!.toList();
      expect(afterDelta.length, 7);

      final d1 = afterDelta[0] as TextInsert;
      expect(
        d1.text,
        text1 + text2,
      );
      expect(d1.attributes, null);

      final d2 = afterDelta[1] as TextInsert;
      expect(d2.text, 'Email');
      expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

      final d3 = afterDelta[2] as TextInsert;
      expect(
        d3.text,
        ' became widespread, and instant messaging services like ',
      );
      expect(d3.attributes, null);

      final d4 = afterDelta[3] as TextInsert;
      expect(d4.text, 'ICQ');
      expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

      final d5 = afterDelta[4] as TextInsert;
      expect(d5.text, ' and ');
      expect(d5.attributes, null);

      final d6 = afterDelta[5] as TextInsert;
      expect(
        d6.text,
        'AOL Instant Messenger',
      );
      expect(d6.attributes, {AppFlowyRichTextKeys.bold: true});

      final d7 = afterDelta[6] as TextInsert;
      expect(
        d7.text,
        ' gained tremendous popularity, allowing for seamless real-time text communication across the globe.',
      );
      expect(d7.attributes, null);
    });

    test('replace markdown text with selection from start to end', () async {
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(delta: Delta()..insert(text1)),
            paragraphNode(delta: Delta()..insert(text2)),
            paragraphNode(delta: Delta()..insert(text3)),
          ],
        ),
      );
      final editorState = EditorState(document: document);

      editorState.selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [0], offset: text1.length),
      );

      final markdownText = '''1. $text1

2. $text1

3. $text1''';
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      await markdownTextRobot.replace(
        selection: editorState.selection!,
        markdownText: markdownText,
      );

      final nodes = editorState.document.root.children;
      expect(nodes.length, 5);

      final d1 = nodes[0].delta!.toList()[0] as TextInsert;
      expect(d1.text, text1);
      expect(d1.attributes, null);
      expect(nodes[0].type, NumberedListBlockKeys.type);

      final d2 = nodes[1].delta!.toList()[1] as TextInsert;
      expect(d2.text, text1);
      expect(d2.attributes, null);
      expect(nodes[1].type, NumberedListBlockKeys.type);

      final d3 = nodes[2].delta!.toList()[2] as TextInsert;
      expect(d3.text, text1);
      expect(d3.attributes, null);
      expect(nodes[2].type, NumberedListBlockKeys.type);

      final d4 = nodes[3].delta!.toList()[3] as TextInsert;
      expect(d4.text, text2);
      expect(d4.attributes, null);

      final d5 = nodes[4].delta!.toList()[4] as TextInsert;
      expect(d5.text, text3);
      expect(d5.attributes, null);
    });
  });

  group('markdown text robot - replace in multiple lines:', () {
    final text1 =
        '''The introduction of the World Wide Web in the early 1990s marked a turning point. ''';
    final text2 =
        '''Tim Berners-Lee's invention made the internet accessible to non-technical users, opening the floodgates for mass adoption. ''';
    final text3 =
        '''Email became widespread, and instant messaging services like ICQ and AOL Instant Messenger gained popularity, allowing for real-time text communication.''';

    Document buildTestDocument() {
      return Document(
        root: pageNode(
          children: [
            paragraphNode(delta: Delta()..insert(text1)),
            paragraphNode(delta: Delta()..insert(text2)),
            paragraphNode(delta: Delta()..insert(text3)),
          ],
        ),
      );
    }

    // 1. create a document with 3 paragraph nodes
    // 2. use the text robot to replace the selected content in the multiple lines
    // 3. check the document
    test(
        'the selection starts with the first paragraph and ends with the middle of second paragraph',
        () async {
      final document = buildTestDocument();
      final editorState = EditorState(document: document);

      editorState.selection = Selection(
        start: Position(
          path: [0],
        ),
        end: Position(
          path: [1],
          offset: text2.length -
              ', opening the floodgates for mass adoption. '.length,
        ),
      );

      final markdownText =
          '''The **introduction** of the World Wide Web in the *early 1990s* marked a significant turning point.

Tim Berners-Lee's **revolutionary invention** made the internet accessible to non-technical users''';
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      await markdownTextRobot.replace(
        selection: editorState.selection!,
        markdownText: markdownText,
      );

      final afterNodes = editorState.document.root.children;
      expect(afterNodes.length, 3);

      {
        // first paragraph
        final delta1 = afterNodes[0].delta!.toList();
        expect(delta1.length, 5);

        final d1 = delta1[0] as TextInsert;
        expect(d1.text, 'The ');
        expect(d1.attributes, null);

        final d2 = delta1[1] as TextInsert;
        expect(d2.text, 'introduction');
        expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

        final d3 = delta1[2] as TextInsert;
        expect(d3.text, ' of the World Wide Web in the ');
        expect(d3.attributes, null);

        final d4 = delta1[3] as TextInsert;
        expect(d4.text, 'early 1990s');
        expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

        final d5 = delta1[4] as TextInsert;
        expect(d5.text, ' marked a significant turning point.');
        expect(d5.attributes, null);
      }

      {
        // second paragraph
        final delta2 = afterNodes[1].delta!.toList();
        expect(delta2.length, 3);

        final d1 = delta2[0] as TextInsert;
        expect(d1.text, "Tim Berners-Lee's ");
        expect(d1.attributes, null);

        final d2 = delta2[1] as TextInsert;
        expect(d2.text, "revolutionary invention");
        expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

        final d3 = delta2[2] as TextInsert;
        expect(
          d3.text,
          " made the internet accessible to non-technical users, opening the floodgates for mass adoption. ",
        );
        expect(d3.attributes, null);
      }

      {
        // third paragraph
        final delta3 = afterNodes[2].delta!.toList();
        expect(delta3.length, 1);

        final d1 = delta3[0] as TextInsert;
        expect(d1.text, text3);
        expect(d1.attributes, null);
      }
    });

    test(
        'the selection starts with the middle of the first paragraph and ends with the middle of last paragraph',
        () async {
      final document = buildTestDocument();
      final editorState = EditorState(document: document);

      editorState.selection = Selection(
        start: Position(
          path: [0],
          offset: 'The introduction of the World Wide Web'.length,
        ),
        end: Position(
          path: [2],
          offset:
              'Email became widespread, and instant messaging services like ICQ and AOL Instant Messenger gained popularity'
                  .length,
        ),
      );

      final markdownText =
          ''' in the **early 1990s** marked a *significant turning point* in technological history.

Tim Berners-Lee's **revolutionary invention** made the internet accessible to non-technical users, opening the floodgates for *unprecedented mass adoption*.

Email became **widely prevalent**, and instant messaging services like *ICQ* and *AOL Instant Messenger* gained tremendous popularity
          ''';
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      await markdownTextRobot.replace(
        selection: editorState.selection!,
        markdownText: markdownText,
      );

      final afterNodes = editorState.document.root.children;
      expect(afterNodes.length, 3);

      {
        // first paragraph
        final delta1 = afterNodes[0].delta!.toList();
        expect(delta1.length, 5);

        final d1 = delta1[0] as TextInsert;
        expect(d1.text, 'The introduction of the World Wide Web in the ');
        expect(d1.attributes, null);

        final d2 = delta1[1] as TextInsert;
        expect(d2.text, 'early 1990s');
        expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

        final d3 = delta1[2] as TextInsert;
        expect(d3.text, ' marked a ');
        expect(d3.attributes, null);

        final d4 = delta1[3] as TextInsert;
        expect(d4.text, 'significant turning point');
        expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

        final d5 = delta1[4] as TextInsert;
        expect(d5.text, ' in technological history.');
        expect(d5.attributes, null);
      }

      {
        // second paragraph
        final delta2 = afterNodes[1].delta!.toList();
        expect(delta2.length, 5);

        final d1 = delta2[0] as TextInsert;
        expect(d1.text, "Tim Berners-Lee's ");
        expect(d1.attributes, null);

        final d2 = delta2[1] as TextInsert;
        expect(d2.text, "revolutionary invention");
        expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

        final d3 = delta2[2] as TextInsert;
        expect(
          d3.text,
          " made the internet accessible to non-technical users, opening the floodgates for ",
        );
        expect(d3.attributes, null);

        final d4 = delta2[3] as TextInsert;
        expect(d4.text, "unprecedented mass adoption");
        expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

        final d5 = delta2[4] as TextInsert;
        expect(d5.text, ".");
        expect(d5.attributes, null);
      }

      {
        // third paragraph
        // third paragraph
        final delta3 = afterNodes[2].delta!.toList();
        expect(delta3.length, 7);

        final d1 = delta3[0] as TextInsert;
        expect(d1.text, "Email became ");
        expect(d1.attributes, null);

        final d2 = delta3[1] as TextInsert;
        expect(d2.text, "widely prevalent");
        expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

        final d3 = delta3[2] as TextInsert;
        expect(d3.text, ", and instant messaging services like ");
        expect(d3.attributes, null);

        final d4 = delta3[3] as TextInsert;
        expect(d4.text, "ICQ");
        expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

        final d5 = delta3[4] as TextInsert;
        expect(d5.text, " and ");
        expect(d5.attributes, null);

        final d6 = delta3[5] as TextInsert;
        expect(d6.text, "AOL Instant Messenger");
        expect(d6.attributes, {AppFlowyRichTextKeys.italic: true});

        final d7 = delta3[6] as TextInsert;
        expect(
          d7.text,
          " gained tremendous popularity, allowing for real-time text communication.",
        );
        expect(d7.attributes, null);
      }
    });

    test(
        'the length of the returned response less than the length of the selected text',
        () async {
      final document = buildTestDocument();
      final editorState = EditorState(document: document);

      editorState.selection = Selection(
        start: Position(
          path: [0],
          offset: 'The introduction of the World Wide Web'.length,
        ),
        end: Position(
          path: [2],
          offset:
              'Email became widespread, and instant messaging services like ICQ and AOL Instant Messenger gained popularity'
                  .length,
        ),
      );

      final markdownText =
          ''' in the **early 1990s** marked a *significant turning point* in technological history.''';
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );
      await markdownTextRobot.replace(
        selection: editorState.selection!,
        markdownText: markdownText,
      );

      final afterNodes = editorState.document.root.children;
      expect(afterNodes.length, 2);

      {
        // first paragraph
        final delta1 = afterNodes[0].delta!.toList();
        expect(delta1.length, 5);

        final d1 = delta1[0] as TextInsert;
        expect(d1.text, "The introduction of the World Wide Web in the ");
        expect(d1.attributes, null);

        final d2 = delta1[1] as TextInsert;
        expect(d2.text, "early 1990s");
        expect(d2.attributes, {AppFlowyRichTextKeys.bold: true});

        final d3 = delta1[2] as TextInsert;
        expect(d3.text, " marked a ");
        expect(d3.attributes, null);

        final d4 = delta1[3] as TextInsert;
        expect(d4.text, "significant turning point");
        expect(d4.attributes, {AppFlowyRichTextKeys.italic: true});

        final d5 = delta1[4] as TextInsert;
        expect(d5.text, " in technological history.");
        expect(d5.attributes, null);
      }

      {
        // second paragraph
        final delta2 = afterNodes[1].delta!.toList();
        expect(delta2.length, 1);

        final d1 = delta2[0] as TextInsert;
        expect(d1.text, ", allowing for real-time text communication.");
        expect(d1.attributes, null);
      }
    });
  });
}

const _sample1 = '''# The Curious Cat

Once upon a time in a **quiet village**, there lived a curious cat named *Whiskers*. Unlike other cats, Whiskers had a passion for **exploration**. Every day, he'd wander through the village, discovering hidden spots and making new friends with the local animals.

One sunny morning, Whiskers stumbled upon a mysterious **wooden box** behind the old barn. It was covered in _vines and dust_. Intrigued, he nudged it open with his paw and found a collection of ancient maps. These maps led to secret trails around the village.

Whiskers became the village's hero, guiding everyone on exciting adventures.''';

const _liveRefreshSample2 = [
  "##",
  " The",
  " Decision",
  "\n\n",
  "-",
  " Ar",
  "ia",
  " found",
  " an",
  " ancient map",
  " in her grandmother",
  "'s attic",
  ".\n",
  "-",
  " The map",
  " hinted at",
  " a",
  " mystical",
  " place",
  " known",
  " as",
  " the",
  " En",
  "ch",
  "anted",
  " Forest",
  ".\n",
  "-",
  " Legends",
  " spoke",
  " of",
  " the",
  " forest",
  " as",
  " a realm",
  " where dreams",
  " came",
  " to",
  " life",
  ".\n\n",
];

const _liveRefreshSample3 = [
  "##",
  " The",
  " Preparation\n\n",
  "Before",
  " embarking",
  " on",
  " her",
  " journey",
  ", Aria prepared",
  " meticulously:\n\n",
  "1",
  ".",
  " **",
  "Gather",
  " Supplies**",
  "  \n",
  "  ",
  " -",
  " A",
  " sturdy",
  " backpack",
  "\n",
  "  ",
  " -",
  " A",
  " compass",
  " and",
  " a map",
  "\n  ",
  " -",
  " Pro",
  "visions",
  " for",
  " the",
  " week",
  "\n\n",
  "2",
  ".",
  " **",
  "Seek",
  " Guidance",
  "**",
  "  \n",
  "  ",
  " -",
  " Vis",
  "ited",
  " the",
  " village",
  " elder for advice",
  "\n",
  "   -",
  " List",
  "ened",
  " to",
  " tales",
  " of past",
  " advent",
  "urers",
  "\n\n",
  "3",
  ".",
  " **",
  "Shar",
  "pen",
  " Skills",
  "**",
  "  \n",
  "  ",
  " -",
  " Pract",
  "iced",
  " arch",
  "ery",
  " and",
  " swordsmanship",
  "\n  ",
  " -",
  " Enhanced",
  " survival skills",
];

const _liveRefreshSample4 = [
  "Sure",
  ", let's",
  " provide an",
  " alternative Rust",
  " implementation for the Two",
  " Sum",
  " problem",
  ",",
  " focusing",
  " on",
  " clarity",
  " and efficiency",
  " but with",
  " a slightly",
  " different approach",
  ":\n\n",
  "```",
  "rust",
  "\nfn two",
  "_sum",
  "(nums",
  ": &[",
  "i",
  "32",
  "],",
  " target",
  ":",
  " i",
  "32",
  ")",
  " ->",
  " Vec",
  "<(usize",
  ", usize",
  ")>",
  " {\n",
  "   ",
  " let",
  " mut results",
  " = Vec::",
  "new",
  "();\n",
  "   ",
  " let mut",
  " map",
  " =",
  " std::collections",
  "::",
  "HashMap",
  "::",
  "new",
  "();\n\n   ",
  " for (",
  "i,",
  " &num",
  ") in",
  " nums.iter",
  "().enumer",
  "ate()",
  " {\n        let",
  " complement",
  " = target",
  " - num",
  ";\n",
  "       ",
  " if",
  " let",
  " Some(&",
  "j)",
  " =",
  " map",
  ".get(&",
  "complement",
  ") {\n",
  "            results",
  ".push((",
  "j",
  ",",
  " i));\n        }\n",
  "       ",
  " map",
  ".insert",
  "(num",
  ", i",
  ");\n",
  "   ",
  " }\n\n   ",
  " results\n",
  "}\n\n",
  "fn",
  " main()",
  " {\n",
  "   ",
  " let",
  " nums",
  " =",
  " vec![2, ",
  "7",
  ",",
  " 11, 15];\n",
  "    let",
  " target",
  " =",
  " ",
  "9",
  ";\n\n",
  "   ",
  " let",
  " pairs",
  " = two",
  "_sum",
  "(&",
  "nums",
  ",",
  " target);\n",
  "   ",
  " if",
  " pairs",
  ".is",
  "_empty()",
  " {\n       ",
  " println",
  "!(\"",
  "No",
  " two",
  " sum solution",
  " found\");\n",
  "   ",
  " }",
  " else {\n        for",
  " (",
  "i",
  ", j",
  ") in",
  " pairs {\n",
  "            println",
  "!(\"Indices",
  ":",
  " {},",
  " {}\",",
  " i",
  ",",
  " j",
  ");\n       ",
  " }\n   ",
  " }\n}\n",
  "```\n\n",
];
