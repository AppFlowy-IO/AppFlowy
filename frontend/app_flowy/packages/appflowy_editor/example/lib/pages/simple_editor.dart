import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
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
            ],
            selectionMenuItems: [
              // Divider
              dividerMenuItem,
              // Math Equation
              mathEquationMenuItem,
              // Code Block
              codeBlockMenuItem,
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
