import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../chat_editor_style.dart';

// Wrap the appflowy_editor as a chat text message widget
class AIMarkdownText extends StatelessWidget {
  const AIMarkdownText({
    super.key,
    required this.markdown,
  });

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DocumentPageStyleBloc(view: ViewPB())
        ..add(const DocumentPageStyleEvent.initial()),
      child: _AppFlowyEditorMarkdown(markdown: markdown),
    );
  }
}

class _AppFlowyEditorMarkdown extends StatefulWidget {
  const _AppFlowyEditorMarkdown({
    required this.markdown,
  });

  // the text should be the markdown format
  final String markdown;

  @override
  State<_AppFlowyEditorMarkdown> createState() =>
      _AppFlowyEditorMarkdownState();
}

class _AppFlowyEditorMarkdownState extends State<_AppFlowyEditorMarkdown> {
  late EditorState editorState;
  late EditorScrollController scrollController;

  @override
  void initState() {
    super.initState();

    editorState = _parseMarkdown(widget.markdown);
    scrollController = EditorScrollController(
      editorState: editorState,
      shrinkWrap: true,
    );
  }

  @override
  void didUpdateWidget(covariant _AppFlowyEditorMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.markdown != widget.markdown) {
      editorState.dispose();
      editorState = _parseMarkdown(widget.markdown);
      scrollController.dispose();
      scrollController = EditorScrollController(
        editorState: editorState,
        shrinkWrap: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    editorState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // don't lazy load the styleCustomizer and blockBuilders,
    // it needs the context to get the theme.
    final styleCustomizer = ChatEditorStyleCustomizer(
      context: context,
      padding: EdgeInsets.zero,
    );
    final editorStyle = styleCustomizer.style().copyWith(
          // hide the cursor
          cursorColor: Colors.transparent,
          cursorWidth: 0,
        );
    final blockBuilders = buildBlockComponentBuilders(
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
        disableKeyboardService: true,
        editorStyle: editorStyle,
        editorScrollController: scrollController,
        blockComponentBuilders: blockBuilders,
        commandShortcutEvents: [customCopyCommand],
        disableAutoScroll: true,
        editorState: editorState,
        contextMenuItems: [
          [
            ContextMenuItem(
              getName: LocaleKeys.document_plugins_contextMenu_copy.tr,
              onPressed: (editorState) =>
                  customCopyCommand.execute(editorState),
            ),
          ]
        ],
      ),
    );
  }

  EditorState _parseMarkdown(String markdown) {
    final document = customMarkdownToDocument(markdown);
    final editorState = EditorState(document: document);
    return editorState;
  }
}
