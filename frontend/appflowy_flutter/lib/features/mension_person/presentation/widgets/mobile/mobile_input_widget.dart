
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MobileInputWidget extends StatefulWidget {
  const MobileInputWidget({
    super.key,
    required this.editorState,
    required this.onDismiss,
    required this.onQuery,
    required this.startOffset,
    required this.child,
  });
  final EditorState editorState;
  final VoidCallback onDismiss;
  final ValueChanged<String> onQuery;

  final int startOffset;
  final Widget child;

  @override
  State<MobileInputWidget> createState() => _MobileInputWidgetState();
}

class _MobileInputWidgetState extends State<MobileInputWidget> {
  final _focusNode = FocusNode(debugLabel: 'mobile_input_widget');
  int invalidCounter = 0;
  String query = '';

  EditorState get editorState => widget.editorState;

  ValueChanged<String> get onQuery => widget.onQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
    keepEditorFocusNotifier.increase();
    editorState.selectionNotifier.addListener(onSelectionChanged);
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(onSelectionChanged);
    _focusNode.dispose();
    keepEditorFocusNotifier.decrease();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _focusNode, child: widget.child);
  }

  void onSelectionChanged() {
    final selection = editorState.selection;
    if (selection == null) {
      dismiss();
      return;
    }
    if (!selection.isCollapsed) {
      dismiss();
      return;
    }
    final startOffset = widget.startOffset;
    final endOffset = selection.end.offset;
    if (endOffset < startOffset) {
      dismiss();
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final text = node?.delta?.toPlainText() ?? '';
    final search = text.substring(startOffset, endOffset);
    query = search;
    onQuery.call(query);
  }

  void dismiss() => widget.onDismiss.call();
}
