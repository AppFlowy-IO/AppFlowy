import 'package:appflowy_editor/appflowy_editor.dart';

enum TextRobotInputType {
  character,
  word,
}

extension TextRobot on EditorState {
  Future<void> autoInsertText(
    String text, {
    TextRobotInputType inputType = TextRobotInputType.word,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    if (text == '\n') {
      await insertNewLineAtCurrentSelection();
      return;
    }
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.isEmpty) {
        await insertNewLineAtCurrentSelection();
        continue;
      }
      switch (inputType) {
        case TextRobotInputType.character:
          final iterator = line.runes.iterator;
          while (iterator.moveNext()) {
            await insertTextAtCurrentSelection(
              iterator.currentAsString,
            );
            await Future.delayed(delay, () {});
          }
          break;
        case TextRobotInputType.word:
          final words = line.split(' ');
          if (words.length == 1 ||
              (words.length == 2 &&
                  (words.first.isEmpty || words.last.isEmpty))) {
            await insertTextAtCurrentSelection(
              line,
            );
          } else {
            for (final word in words.map((e) => '$e ')) {
              await insertTextAtCurrentSelection(
                word,
              );
            }
          }
          await Future.delayed(delay, () {});
          break;
      }
    }
  }
}
