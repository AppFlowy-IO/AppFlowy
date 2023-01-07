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
    var path = 0;
    for (final line in lines) {
      switch (inputType) {
        case TextRobotInputType.character:
          var index = 0;
          final iterator = line.runes.iterator;
          while (iterator.moveNext()) {
            // await editorState.insertText(
            //   index,
            //   iterator.currentAsString,
            //   path: [path],
            // );
            await editorState.insertTextAtCurrentSelection(
              iterator.currentAsString,
            );
            index += iterator.currentSize;
            await Future.delayed(delay);
          }
          path += 1;
          break;
        default:
      }

      // insert new line
      await editorState.insertNewLine(editorState, [path]);
    }
  }
}
