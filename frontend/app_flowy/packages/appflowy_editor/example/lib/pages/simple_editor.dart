import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:example/plugin/AI/continue_to_write.dart';
import 'package:example/plugin/AI/auto_completion.dart';
import 'package:example/plugin/AI/getgpt3completions.dart';
import 'package:flutter/material.dart';

class SimpleEditor extends StatelessWidget {
  const SimpleEditor({
    super.key,
    required this.jsonString,
    required this.themeData,
    required this.onEditorStateChange,
  });

  final Future<String> jsonString;
  final ThemeData themeData;
  final void Function(EditorState editorState) onEditorStateChange;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: jsonString,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final editorState = EditorState(
            document: Document.fromJson(
              Map<String, Object>.from(
                json.decode(snapshot.data!),
              ),
            ),
          );
          editorState.logConfiguration
            ..handler = debugPrint
            ..level = LogLevel.all;
          onEditorStateChange(editorState);

          return AppFlowyEditor(
            editorState: editorState,
            themeData: themeData,
            autoFocus: editorState.document.isEmpty,
            customBuilders: {
              // Divider
              kDividerType: DividerWidgetBuilder(),
              // Math Equation
              kMathEquationType: MathEquationNodeWidgetBuidler(),
              // Code Block
              kCodeBlockType: CodeBlockNodeWidgetBuilder(),
            },
            shortcutEvents: [
              // Divider
              insertDividerEvent,
              // Code Block
              enterInCodeBlock,
              ignoreKeysInCodeBlock,
              pasteInCodeBlock,
            ],
            selectionMenuItems: [
              // Divider
              dividerMenuItem,
              // Math Equation
              mathEquationMenuItem,
              // Code Block
              codeBlockMenuItem,
              // Emoji
              emojiMenuItem,
              // Open AI
              if (apiKey.isNotEmpty) ...[
                autoCompletionMenuItem,
                continueToWriteMenuItem,
              ]
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
