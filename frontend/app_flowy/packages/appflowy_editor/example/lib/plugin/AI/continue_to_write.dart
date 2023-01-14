import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/plugin/AI/gpt3.dart';
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
    // Two cases
    // 1. if there is content in the text node where the cursor is located,
    //  then we use the current text content as data.
    // 2. if there is no content in the text node where the cursor is located,
    // then we use the previous / next text node's content as data.

    final selection =
        editorState.service.selectionService.currentSelection.value;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (textNodes.isEmpty) {
      return;
    }

    final textRobot = TextRobot(editorState: editorState);
    const gpt3 = GPT3APIClient(apiKey: apiKey);
    final textNode = textNodes.first;

    var prompt = '';
    var suffix = '';

    void continueToWriteInSingleLine() {
      prompt = textNode.delta.slice(0, selection.startIndex).toPlainText();
      suffix = textNode.delta
          .slice(
            selection.endIndex,
            textNode.toPlainText().length,
          )
          .toPlainText();
    }

    void continueToWriteInMulitLines() {
      final parent = textNode.parent;
      if (parent != null) {
        for (final node in parent.children) {
          if (node is! TextNode || node.toPlainText().isEmpty) continue;
          if (node.path < textNode.path) {
            prompt += '${node.toPlainText()}\n';
          } else if (node.path > textNode.path) {
            suffix += '${node.toPlainText()}\n';
          }
        }
      }
    }

    if (textNodes.first.toPlainText().isNotEmpty) {
      continueToWriteInSingleLine();
    } else {
      continueToWriteInMulitLines();
    }

    if (prompt.isEmpty && suffix.isEmpty) {
      return;
    }

    late final BuildContext diglogContext;

    showDialog(
      context: context,
      builder: (context) {
        diglogContext = context;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Loading'),
            ],
          ),
        );
      },
    );

    gpt3.getGPT3Completion(
      prompt,
      suffix,
      onResult: (result) async {
        Navigator.of(diglogContext).pop(true);
        await textRobot.insertText(
          result,
          inputType: TextRobotInputType.word,
        );
      },
      onError: () async {
        Navigator.of(diglogContext).pop(true);
      },
    );
  }),
);
