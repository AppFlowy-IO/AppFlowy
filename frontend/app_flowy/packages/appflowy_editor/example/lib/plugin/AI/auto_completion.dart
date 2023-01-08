import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/plugin/AI/getgpt3completions.dart';
import 'package:example/plugin/AI/text_robot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SelectionMenuItem autoCompletionMenuItem = SelectionMenuItem(
  name: () => 'Auto generate content',
  icon: (editorState, onSelected) => Icon(
    Icons.rocket,
    size: 18.0,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
  ),
  keywords: ['auto generate content', 'open ai', 'gpt3', 'ai'],
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
                final textRobot = TextRobot(editorState: editorState);
                getGPT3Completion(apiKey, controller.text, '', (result) async {
                  await textRobot.insertText(
                    result,
                    inputType: TextRobotInputType.character,
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
