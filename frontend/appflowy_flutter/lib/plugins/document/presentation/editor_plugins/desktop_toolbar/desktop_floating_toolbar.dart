import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'toolbar_animation.dart';

class DesktopFloatingToolbar extends StatefulWidget {
  const DesktopFloatingToolbar({
    super.key,
    required this.editorState,
    required this.child,
  });

  final EditorState editorState;
  final Widget child;

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
    return Positioned(
      left: position!.left,
      top: position!.top,
      right: position!.right,
      child: ToolbarAnimationWidget(
        child: widget.child,
      ),
    );
  }

  _Position calculateSelectionMenuOffset(
    Rect rect,
  ) {
    final bool isLongMenu = onlyShowInSingleSelectionAndTextType(editorState);
    final menuWidth = isLongMenu ? 650.0 : 420.0;
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorSize = editorState.renderBox?.size ?? Size.zero;
    final editorRect = editorOffset & editorSize;
    final left = rect.left, leftStart = 50;
    final top = rect.top < 40 ? rect.bottom + 40 : rect.top - 40;
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

class _Position {
  _Position(this.left, this.top, this.right);

  final double? left;
  final double? top;
  final double? right;
}
