import 'package:appflowy/plugins/document/presentation/editor_plugins/base/markdown_text_robot.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
      await markdownTextRobot.stop();

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
      await markdownTextRobot.stop();

      final nodes = editorState.document.root.children;
      // 4 from the sample, 1 from the original empty paragraph node
      expect(nodes.length, 5);

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
          expect(nodes.length, 5);

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
          expect(nodes.length, 6);

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
