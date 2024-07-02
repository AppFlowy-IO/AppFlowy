import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

// Wrap the appflowy_editor as a chat text message widget
class AITextEditor extends StatefulWidget {
  const AITextEditor({
    super.key,
    required this.markdown,
  });

  // the text should be the markdown format
  final String markdown;

  @override
  State<AITextEditor> createState() => _AITextEditorState();
}

class _AITextEditorState extends State<AITextEditor> {
  late EditorState editorState;
  late final styleCustomizer = EditorStyleCustomizer(
    context: context,
    padding: EdgeInsets.zero,
  );

  @override
  void initState() {
    super.initState();

    editorState = _parseMarkdown(widget.markdown);
  }

  @override
  void didUpdateWidget(covariant AITextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.markdown != widget.markdown) {
      editorState.dispose();
      editorState = _parseMarkdown(widget.markdown);
    }
  }

  @override
  void dispose() {
    editorState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockBuilders = getEditorBuilderMap(
      context: context,
      editorState: editorState,
      styleCustomizer: styleCustomizer,
      // the editor is not editable in the chat
      editable: false,
    );
    return IntrinsicHeight(
      child: AppFlowyEditor(
        shrinkWrap: true,
        // the editor is not editable in the chat
        editable: false,
        editorStyle: styleCustomizer.style(),
        blockComponentBuilders: blockBuilders,
        editorState: editorState,
      ),
    );
  }

  EditorState _parseMarkdown(String markdown) {
    final document = markdownToDocument(markdown);
    final editorState = EditorState(document: document);
    return editorState;
  }
}
