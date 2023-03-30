import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({
    super.key,
    required this.editorState,
    required this.child,
  });

  final EditorState editorState;
  final Widget child;

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.editorState.service.selectionServiceV2
          .addListener(_onSelectionChanged);
    });
  }

  @override
  void dispose() {
    widget.editorState.service.selectionServiceV2
        .removeListener(_onSelectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _onSelectionChanged() {
    final selection = widget.editorState.service.selectionServiceV2.selection;
    if (selection == null || selection.isCollapsed) {
      _clear();
    } else {
      _show();
    }
  }

  void _clear() {}

  void _show() {}
}
