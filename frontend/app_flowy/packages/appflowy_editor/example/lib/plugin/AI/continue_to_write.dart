import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/plugin/AI/getgpt3completions.dart';
import 'package:example/plugin/AI/text_robot.dart';
import 'package:flutter/material.dart';

SelectionMenuItem continueToWriteMenuItem = SelectionMenuItem(
  name: () => 'Continue To Write',
  icon: (editorState, onSelected) => Icon(
    Icons.print,
    size: 18.0,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
  ),
  keywords: ['continue to write'],
  handler: ((editorState, menuService, context) async {
    // get the current text
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes;
    if (selection == null || !selection.isCollapsed || textNodes.length != 1) {
      return;
    }
    final textNode = textNodes.first as TextNode;
    final prompt = textNode.delta.slice(0, selection.startIndex).toPlainText();
    final suffix = textNode.delta
        .slice(
          selection.endIndex,
          textNode.toPlainText().length,
        )
        .toPlainText();
    debugPrint('AI: prompt = $prompt, suffix = $suffix');
    final textRobot = TextRobot(editorState: editorState);
    getGPT3Completion(
      apiKey,
      prompt,
      suffix,
      (result) async {
        if (result == '\\n') {
          await editorState.insertNewLineAtCurrentSelection();
        } else {
          await textRobot.insertText(
            result,
            inputType: TextRobotInputType.word,
          );
        }
      },
    );
  }),
);
