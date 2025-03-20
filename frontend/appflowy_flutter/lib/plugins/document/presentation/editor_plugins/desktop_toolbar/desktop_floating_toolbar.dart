import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class DesktopFloatingToolbar extends StatefulWidget {
  const DesktopFloatingToolbar({
    super.key,
    required this.editorState,
    required this.child,
    required this.onDismiss,
  });

  final EditorState editorState;
  final Widget child;
  final VoidCallback onDismiss;

  @override
  State<DesktopFloatingToolbar> createState() => _DesktopFloatingToolbarState();
}

class _DesktopFloatingToolbarState extends State<DesktopFloatingToolbar> {
  EditorState get editorState => widget.editorState;

  _Position? position;

  @override
  void initState() {
    super.initState();
    final selection = editorState.selection;
    if (selection == null || selection.isCollapsed) {
      return;
    }
    final selectionRect = editorState.selectionRects();
    if (selectionRect.isEmpty) return;
    position = calculateSelectionMenuOffset(selectionRect.first);
  }

  @override
  Widget build(BuildContext context) {
    if (position == null) return Container();
    return InheritedToolbar(
      controller: ToolbarDismissController(widget.onDismiss),
      child: Positioned(
        left: position!.left,
        top: position!.top,
        right: position!.right,
        child: widget.child,
      ),
    );
  }

  _Position calculateSelectionMenuOffset(
    Rect rect,
  ) {
    const toolbarHeight = 40, topLimit = toolbarHeight + 8;
    final bool isLongMenu = onlyShowInSingleSelectionAndTextType(editorState);
    final menuWidth = isLongMenu ? 650.0 : 420.0;
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorSize = editorState.renderBox?.size ?? Size.zero;
    final editorRect = editorOffset & editorSize;
    final left = rect.left, leftStart = 50;
    final top =
        rect.top < topLimit ? rect.bottom + topLimit : rect.top - topLimit;
    if (left + menuWidth > editorRect.right) {
      return _Position(
        editorRect.right - menuWidth,
        top,
        null,
      );
    } else if (rect.left - leftStart > 0) {
      return _Position(rect.left - leftStart, top, null);
    } else {
      return _Position(rect.left, top, null);
    }
  }
}

class InheritedToolbar extends InheritedWidget {
  const InheritedToolbar({
    required this.controller,
    required super.child,
    super.key,
  });

  final ToolbarDismissController controller;

  @override
  bool updateShouldNotify(InheritedToolbar oldWidget) =>
      controller != oldWidget.controller;

  static InheritedToolbar? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedToolbar>();
}

class _Position {
  _Position(this.left, this.top, this.right);

  final double? left;
  final double? top;
  final double? right;
}

class ToolbarDismissController {
  ToolbarDismissController(this.onDismiss);

  final VoidCallback onDismiss;

  void dismiss() => onDismiss.call();
}
