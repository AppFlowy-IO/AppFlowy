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

    test('auto insert text with sentence mode (1)', () async {
      final editorState = EditorState.blank();
      editorState.selection = Selection.collapsed(Position(path: [0]));
      final textRobot = TextRobot(
        editorState: editorState,
      );
      for (final text in _sample1) {
        await textRobot.autoInsertText(
          text,
          separator: r'\n\n',
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

    test('auto insert text with sentence mode (2)', () async {
      final editorState = EditorState.blank();
      editorState.selection = Selection.collapsed(Position(path: [0]));
      final textRobot = TextRobot(
        editorState: editorState,
      );

      var breakCount = 0;
      for (final text in _sample2) {
        if (text.contains('\n\n')) {
          breakCount++;
        }
        await textRobot.autoInsertText(
          text,
          separator: r'\n\n',
          inputType: TextRobotInputType.sentence,
          delay: Duration.zero,
        );
      }

      final len = editorState.document.root.children.length;
      expect(len, breakCount + 1);
      expect(len, 7);

      final p1 = editorState.document.nodeAtPath([0])!.delta!.toPlainText();
      final p2 = editorState.document.nodeAtPath([1])!.delta!.toPlainText();
      final p3 = editorState.document.nodeAtPath([2])!.delta!.toPlainText();
      final p4 = editorState.document.nodeAtPath([3])!.delta!.toPlainText();
      final p5 = editorState.document.nodeAtPath([4])!.delta!.toPlainText();
      final p6 = editorState.document.nodeAtPath([5])!.delta!.toPlainText();
      final p7 = editorState.document.nodeAtPath([6])!.delta!.toPlainText();

      expect(
        p1,
        'Once upon a time in the small, whimsical village of Greenhollow, nestled between rolling hills and lush forests, there lived a young girl named Elara. Unlike the other villagers, Elara had a unique gift: she could communicate with animals. This extraordinary ability made her both a beloved and mysterious figure in Greenhollow.',
      );
      expect(
        p2,
        'One crisp autumn morning, as golden leaves danced in the breeze, Elara heard a distressed call from the forest. Following the sound, she discovered a young fox trapped in a hunter\'s snare. With gentle hands and a calming voice, she freed the frightened creature, who introduced himself as Rufus. Grateful for her help, Rufus promised to assist Elara whenever she needed.',
      );
      expect(
        p3,
        'Word of Elara\'s kindness spread among the forest animals, and soon she found herself surrounded by a diverse group of animal friends, from wise old owls to playful otters. Together, they shared stories, solved problems, and looked out for one another.',
      );
      expect(
        p4,
        'One day, the village faced an unexpected threat: a severe drought that threatened their crops and water supply. The villagers grew anxious, unsure of how to cope with the impending scarcity. Elara, determined to help, turned to her animal friends for guidance.',
      );
      expect(
        p5,
        'The animals led Elara to a hidden spring deep within the forest, a source of fresh water unknown to the villagers. With Rufus\'s clever planning and the otters\' help in directing the flow, they managed to channel the spring water to the village, saving the crops and quenching the villagers\' thirst.',
      );
      expect(
        p6,
        'Grateful and amazed, the villagers hailed Elara as a hero. They came to understand the importance of living harmoniously with nature and the wonders that could be achieved through kindness and cooperation.',
      );
      expect(
        p7,
        'From that day on, Greenhollow thrived as a community where humans and animals lived together in harmony, cherishing the bonds that Elara had helped forge. And whenever challenges arose, the villagers knew they could rely on Elara and her extraordinary friends to guide them through, ensuring that the spirit of unity and compassion always prevailed.',
      );
    });
  });
}

final _sample1 = [
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

final _sample2 = [
  "Once",
  " upon",
  " a",
  " time",
  " in",
  " the small",
  ",",
  " whimsical",
  " village",
  " of",
  " Green",
  "h",
  "ollow",
  ",",
  " nestled",
  " between",
  " rolling hills",
  " and",
  " lush",
  " forests",
  ",",
  " there",
  " lived",
  " a young",
  " girl",
  " named",
  " Elara.",
  " Unlike the",
  " other",
  " villagers",
  ",",
  " El",
  "ara",
  " had",
  " a unique",
  " gift",
  ":",
  " she could",
  " communicate",
  " with",
  " animals",
  ".",
  " This",
  " extraordinary",
  " ability",
  " made",
  " her both a",
  " beloved",
  " and",
  " mysterious",
  " figure",
  " in",
  " Green",
  "h",
  "ollow",
  ".\n\n",
  "One",
  " crisp",
  " autumn",
  " morning,",
  " as",
  " golden",
  " leaves",
  " danced",
  " in",
  " the",
  " breeze",
  ", El",
  "ara heard",
  " a distressed",
  " call",
  " from",
  " the",
  " forest",
  ".",
  " Following",
  " the",
  " sound",
  ",",
  " she",
  " discovered",
  " a",
  " young",
  " fox",
  " trapped",
  " in",
  " a",
  " hunter's",
  " snare",
  ".",
  " With",
  " gentle",
  " hands",
  " and",
  " a",
  " calming",
  " voice",
  ",",
  " she",
  " freed",
  " the",
  " frightened",
  " creature",
  ", who",
  " introduced",
  " himself",
  " as Ruf",
  "us.",
  " Gr",
  "ateful",
  " for",
  " her",
  " help",
  ",",
  " Rufus promised",
  " to assist",
  " Elara",
  " whenever",
  " she",
  " needed.\n\n",
  "Word",
  " of",
  " Elara",
  "'s kindness",
  " spread among",
  " the forest",
  " animals",
  ",",
  " and soon",
  " she",
  " found",
  " herself",
  " surrounded",
  " by",
  " a",
  " diverse",
  " group",
  " of",
  " animal",
  " friends",
  ",",
  " from",
  " wise",
  " old ow",
  "ls to playful",
  " ot",
  "ters.",
  " Together,",
  " they",
  " shared stories",
  ",",
  " solved problems",
  ",",
  " and",
  " looked",
  " out",
  " for",
  " one",
  " another",
  ".\n\n",
  "One",
  " day",
  ", the village faced",
  " an unexpected",
  " threat",
  ":",
  " a",
  " severe",
  " drought",
  " that",
  " threatened",
  " their",
  " crops",
  " and",
  " water supply",
  ".",
  " The",
  " villagers",
  " grew",
  " anxious",
  ",",
  " unsure",
  " of",
  " how to",
  " cope",
  " with",
  " the",
  " impending",
  " scarcity",
  ".",
  " El",
  "ara",
  ",",
  " determined",
  " to",
  " help",
  ",",
  " turned",
  " to her",
  " animal friends",
  " for",
  " guidance",
  ".\n\nThe",
  " animals",
  " led",
  " El",
  "ara",
  " to",
  " a",
  " hidden",
  " spring",
  " deep",
  " within",
  " the forest,",
  " a source",
  " of",
  " fresh",
  " water unknown",
  " to the",
  " villagers",
  ".",
  " With",
  " Ruf",
  "us's",
  " clever planning",
  " and the",
  " ot",
  "ters",
  "'",
  " help",
  " in directing",
  " the",
  " flow",
  ",",
  " they",
  " managed",
  " to",
  " channel the",
  " spring",
  " water",
  " to",
  " the",
  " village,",
  " saving the",
  " crops",
  " and",
  " quenching",
  " the",
  " villagers",
  "'",
  " thirst",
  ".\n\n",
  "Gr",
  "ateful and",
  " amazed,",
  " the",
  " villagers",
  " hailed El",
  "ara as",
  " a",
  " hero",
  ".",
  " They",
  " came",
  " to",
  " understand the",
  " importance",
  " of living",
  " harmon",
  "iously",
  " with",
  " nature",
  " and",
  " the",
  " wonders",
  " that",
  " could",
  " be",
  " achieved",
  " through kindness",
  " and cooperation",
  ".\n\nFrom",
  " that day",
  " on",
  ",",
  " Greenh",
  "ollow",
  " thr",
  "ived",
  " as",
  " a",
  " community",
  " where",
  " humans",
  " and",
  " animals",
  " lived together",
  " in",
  " harmony",
  ",",
  " cher",
  "ishing",
  " the",
  " bonds that",
  " El",
  "ara",
  " had",
  " helped",
  " forge",
  ".",
  " And whenever",
  " challenges arose",
  ", the",
  " villagers",
  " knew",
  " they",
  " could",
  " rely on",
  " El",
  "ara and",
  " her",
  " extraordinary",
  " friends",
  " to",
  " guide them",
  " through",
  ",",
  " ensuring",
  " that",
  " the",
  " spirit",
  " of",
  " unity",
  " and",
  " compassion",
  " always prevailed.",
];
