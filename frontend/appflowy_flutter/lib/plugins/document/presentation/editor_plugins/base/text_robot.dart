import 'package:appflowy_editor/appflowy_editor.dart';

enum TextRobotInputType {
  character,
  word,
  sentence,
}

class TextRobot {
  const TextRobot({
    required this.editorState,
  });

  final EditorState editorState;

  Future<void> autoInsertText(
    String text, {
    TextRobotInputType inputType = TextRobotInputType.word,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    if (text == '\n') {
      return editorState.insertNewLine();
    }
    final lines = text.split('\n');
    for (final line in lines) {
      switch (inputType) {
        case TextRobotInputType.character:
          if (line.isEmpty) {
            await editorState.insertNewLine();
            continue;
          }
          await insertCharacter(line, delay);
          break;
        case TextRobotInputType.word:
          if (line.isEmpty) {
            await editorState.insertNewLine();
            continue;
          }
          await insertWord(line, delay);
          break;
        case TextRobotInputType.sentence:
          await insertSentence(line, delay);
          break;
      }
    }
  }

  Future<void> insertCharacter(String line, Duration delay) async {
    final iterator = line.runes.iterator;
    while (iterator.moveNext()) {
      await editorState.insertTextAtCurrentSelection(
        iterator.currentAsString,
      );
      await Future.delayed(delay);
    }
  }

  Future<void> insertWord(String line, Duration delay) async {
    final words = line.split(' ');
    if (words.length == 1 ||
        (words.length == 2 && (words.first.isEmpty || words.last.isEmpty))) {
      await editorState.insertTextAtCurrentSelection(
        line,
      );
    } else {
      for (final word in words.map((e) => '$e ')) {
        await editorState.insertTextAtCurrentSelection(
          word,
        );
      }
    }
    await Future.delayed(delay);
  }

  Future<void> insertSentence(String line, Duration delay) async {
    await editorState.insertTextAtCurrentSelection(line);
    await Future.delayed(delay);
  }
}
