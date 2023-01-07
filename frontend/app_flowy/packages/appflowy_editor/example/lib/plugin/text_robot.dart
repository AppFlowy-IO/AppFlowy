import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/plugin/AI/getgpt3completions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SelectionMenuItem textRobotMenuItem = SelectionMenuItem(
  name: () => 'Open AI',
  icon: (editorState, onSelected) => Icon(
    Icons.rocket,
    size: 18.0,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
  ),
  keywords: ['open ai', 'gpt3', 'ai'],
  handler: ((editorState, menuService, context) async {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: '');
        return AlertDialog(
          content: RawKeyboardListener(
            focusNode: FocusNode(),
            child: TextField(
              autofocus: true,
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Please input something...',
              ),
            ),
            onKey: (key) {
              if (key is! RawKeyDownEvent) return;
              if (key.logicalKey == LogicalKeyboardKey.enter) {
                Navigator.of(context).pop();
                // fetch the result and insert it
                // Please fill in your own API key
                getGPT3Completion('', controller.text, '', 200, .3,
                    (result) async {
                  await editorState.insertTextAtCurrentSelection(
                    result,
                  );
                });
              } else if (key.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      },
    );
  }),
);

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
      switch (inputType) {
        case TextRobotInputType.character:
          final iterator = line.runes.iterator;
          while (iterator.moveNext()) {
            await editorState.insertTextAtCurrentSelection(
              iterator.currentAsString,
            );
            await Future.delayed(delay);
          }
          break;
        default:
      }

      // insert new line
      if (lines.length > 1) {
        await editorState.insertNewLine(editorState);
      }
    }
  }
}
