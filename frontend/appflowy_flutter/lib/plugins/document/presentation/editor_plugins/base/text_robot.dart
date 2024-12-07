import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

enum TextRobotInputType {
  character,
  word,
  sentence,
}

class TextRobot {
  TextRobot({
    required this.editorState,
  });

  final EditorState editorState;
  final Lock lock = Lock();

  /// This function is used to insert text in a synchronized way
  ///
  /// It is suitable for inserting text in a loop.
  Future<void> autoInsertTextSync(
    String text, {
    TextRobotInputType inputType = TextRobotInputType.word,
    Duration delay = const Duration(milliseconds: 10),
    String separator = '\n',
  }) async {
    await lock.synchronized(() async {
      await autoInsertText(
        text,
        inputType: inputType,
        delay: delay,
        separator: separator,
      );
    });
  }

  /// This function is used to insert text in an asynchronous way
  ///
  /// It is suitable for inserting a long paragraph or a long sentence.
  Future<void> autoInsertText(
    String text, {
    TextRobotInputType inputType = TextRobotInputType.word,
    Duration delay = const Duration(milliseconds: 10),
    String separator = '\n',
  }) async {
    if (text == separator) {
      await insertNewParagraph(delay);
      return;
    }
    final lines = _splitText(text, separator);
    for (final line in lines) {
      if (line.isEmpty) {
        await insertNewParagraph(delay);
        continue;
      }
      switch (inputType) {
        case TextRobotInputType.character:
          await insertCharacter(line, delay);
          break;
        case TextRobotInputType.word:
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
      await insertText(iterator.currentAsString, delay);
    }
  }

  Future<void> insertWord(String line, Duration delay) async {
    final words = line.split(' ');
    if (words.length == 1 ||
        (words.length == 2 && (words.first.isEmpty || words.last.isEmpty))) {
      await insertText(line, delay);
    } else {
      for (final word in words.map((e) => '$e ')) {
        await insertText(word, delay);
      }
    }
    await Future.delayed(delay);
  }

  Future<void> insertSentence(String line, Duration delay) async {
    await insertText(line, delay);
  }

  Future<void> insertNewParagraph(Duration delay) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final next = selection.end.path.next;
    final transaction = editorState.transaction;
    transaction.insertNode(
      next,
      paragraphNode(),
    );
    transaction.afterSelection = Selection.collapsed(
      Position(path: next),
    );
    await editorState.apply(transaction);
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> insertText(String text, Duration delay) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final transaction = editorState.transaction;
    transaction.insertText(node, selection.endIndex, text);
    await editorState.apply(transaction);
    await Future.delayed(delay);

    debugPrint(
      'AI insertText: path: ${selection.end.path}, index: ${selection.endIndex}, text: "$text"',
    );
  }
}

List<String> _splitText(String text, String separator) {
  final parts = text.split(RegExp(separator));
  final result = <String>[];

  for (int i = 0; i < parts.length; i++) {
    result.add(parts[i]);
    // Only add empty string if it's not the last part and the next part is not empty
    if (i < parts.length - 1 && parts[i + 1].isNotEmpty) {
      result.add('');
    }
  }

  return result;
}
