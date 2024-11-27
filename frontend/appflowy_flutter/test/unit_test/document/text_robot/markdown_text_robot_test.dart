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

    test('live refresh', () async {
      final editorState = EditorState.blank();
      editorState.selection = Selection.collapsed(Position(path: [0]));
      final markdownTextRobot = MarkdownTextRobot(
        editorState: editorState,
      );

      markdownTextRobot.start();
      for (final text in _liveRefreshSample1) {
        await markdownTextRobot.appendMarkdownText(text);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await Future.delayed(const Duration(milliseconds: 200));
      await markdownTextRobot.stop();

      final nodes = editorState.document.root.children;
      expect(nodes.length, 4);
    });

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
  });
}

const _liveRefreshSample1 = [
  "#",
  " The En",
  "ch",
  "anted",
  " Garden",
  "\n\n",
  "Once",
  " upon",
  " a",
  " time",
  ",",
  " in",
  " a quiet village",
  ",",
  " there",
  " was",
  " a mysterious garden",
  ".",
  " Vill",
  "agers",
  " whispered",
  " about",
  " its",
  " **ench",
  "anted",
  "**",
  " nature",
  ".",
  " The",
  " garden",
  " was hidden",
  " behind",
  " a",
  " gate of",
  " *",
  "twisting",
  " vines",
  "*. One",
  " day,",
  " a curious",
  " child",
  " named",
  " Lily discovered",
  " the gate",
  " slightly",
  " aj",
  "ar.",
  " \n\nInside",
  ",",
  " the",
  " garden was",
  " alive",
  " with",
  " vibrant colors",
  " and the",
  " gentle",
  " hum",
  " of bees",
  ".",
  " In",
  " the center",
  " stood a",
  " **magn",
  "ificent**",
  " tree,",
  " its branches",
  " *",
  "sparkling",
  "*",
  " with",
  " tiny",
  " lights",
  ".",
  " As Lily",
  " approached",
  ",",
  " the tree",
  " spoke,",
  " offering",
  " wisdom",
  " and granting",
  " wishes to",
  " those pure of",
  " heart.",
  " Lily",
  " wished",
  " for happiness",
  " for",
  " her",
  " village,",
  " and from",
  " that",
  " day",
  ", joy",
  " blossomed",
  " everywhere.",
];

const _sample1 = '''# The Curious Cat

Once upon a time in a **quiet village**, there lived a curious cat named *Whiskers*. Unlike other cats, Whiskers had a passion for **exploration**. Every day, he'd wander through the village, discovering hidden spots and making new friends with the local animals.

One sunny morning, Whiskers stumbled upon a mysterious **wooden box** behind the old barn. It was covered in _vines and dust_. Intrigued, he nudged it open with his paw and found a collection of ancient maps. These maps led to secret trails around the village.

Whiskers became the village's hero, guiding everyone on exciting adventures.''';
