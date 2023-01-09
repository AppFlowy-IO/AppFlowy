import 'package:appflowy_editor/appflowy_editor.dart';

enum TextRobotInputType {
  character,
  word,
}

class TextRobot {
  const TextRobot({
    required this.editorState,
    this.delay = const Duration(milliseconds: 30),
  });

  final EditorState editorState;
  final Duration delay;

  Future<void> insertText(
    String text, {
    TextRobotInputType inputType = TextRobotInputType.character,
  }) async {
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;
      switch (inputType) {
        case TextRobotInputType.character:
          final iterator = line.runes.iterator;
          while (iterator.moveNext()) {
            await editorState.insertTextAtCurrentSelection(
              iterator.currentAsString,
            );
            await Future.delayed(delay, () {});
          }
          break;
        case TextRobotInputType.word:
          final words = line.split(' ').map((e) => '$e ');
          for (final word in words) {
            await editorState.insertTextAtCurrentSelection(
              word,
            );
            await Future.delayed(delay, () {});
          }
          break;
      }

      // insert new line
      if (lines.length > 1) {
        await editorState.insertNewLineAtCurrentSelection();
      }
    }
  }
}
