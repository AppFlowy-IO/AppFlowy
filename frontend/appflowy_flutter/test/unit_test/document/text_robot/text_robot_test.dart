import 'package:appflowy/plugins/document/presentation/editor_plugins/base/text_robot.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text robot:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('auto insert text with sentence mode', () async {
      final sample = [
        "In",
        " a quaint",
        " village",
        " nestled",
        " between",
        " rolling",
        " hills",
        ",",
        " a",
        " young",
        " girl",
        " named",
        " El",
        "ara discovered",
        " a hidden",
        " garden",
        ".",
        " She stumbled",
        " upon",
        " it",
        " while",
        " chasing",
        " a",
        " misch",
        "iev",
        "ous rabbit",
        " through",
        " a",
        " narrow,",
        " winding path",
        ".",
        " \n\n",
        "The",
        " garden",
        " was",
        " a",
        " vibrant",
        " oasis",
        ",",
        " br",
        "imming with",
        " colorful",
        " flowers",
        " and whisper",
        "ing",
        " trees",
        ".",
        " El",
        "ara",
        " felt",
        " an inexp",
        "licable",
        " connection",
        " to",
        " the",
        " place,",
        " as",
        " if",
        " it held",
        " secrets",
        " from",
        " a",
        " forgotten",
        " time",
        ".",
        " \n\n",
        "Determ",
        "ined to",
        " uncover",
        " its",
        " mysteries",
        ",",
        " she",
        " visited",
        " daily,",
        " unravel",
        "ing",
        " tales",
        " of",
        " ancient",
        " magic",
        " and",
        " wisdom",
        ".",
        " The",
        " garden transformed",
        " her",
        " spirit",
        ", teaching",
        " her the",
        " importance of harmony and",
        " the",
        " beauty",
        " of",
        " nature",
        "'s wonders.",
      ];
      final editorState = EditorState.blank();
      editorState.selection = Selection.collapsed(Position(path: [0]));
      final textRobot = TextRobot(
        editorState: editorState,
      );
      for (final text in sample) {
        await textRobot.autoInsertText(
          text,
          separator: '\n\n',
          inputType: TextRobotInputType.sentence,
          delay: Duration.zero,
        );
      }

      final p1 = editorState.document.nodeAtPath([0])!.delta!.toPlainText();
      final p2 = editorState.document.nodeAtPath([1])!.delta!.toPlainText();
      final p3 = editorState.document.nodeAtPath([2])!.delta!.toPlainText();

      expect(
        p1,
        'In a quaint village nestled between rolling hills, a young girl named Elara discovered a hidden garden. She stumbled upon it while chasing a mischievous rabbit through a narrow, winding path. ',
      );
      expect(
        p2,
        'The garden was a vibrant oasis, brimming with colorful flowers and whispering trees. Elara felt an inexplicable connection to the place, as if it held secrets from a forgotten time. ',
      );
      expect(
        p3,
        'Determined to uncover its mysteries, she visited daily, unraveling tales of ancient magic and wisdom. The garden transformed her spirit, teaching her the importance of harmony and the beauty of nature\'s wonders.',
      );
    });
  });
}
