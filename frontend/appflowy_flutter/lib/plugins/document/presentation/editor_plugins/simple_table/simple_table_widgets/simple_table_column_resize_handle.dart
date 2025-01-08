import 'dart:ui';

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class SimpleTableColumnResizeHandle extends StatefulWidget {
  const SimpleTableColumnResizeHandle({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<SimpleTableColumnResizeHandle> createState() =>
      _SimpleTableColumnResizeHandleState();
}

class _SimpleTableColumnResizeHandleState
    extends State<SimpleTableColumnResizeHandle> {
  late final simpleTableContext = context.read<SimpleTableContext>();

  bool isStartDragging = false;

  // record the previous position of the drag
  double previousDx = 0;

  @override
  Widget build(BuildContext context) {
    return UniversalPlatform.isMobile
        ? _buildMobileResizeHandle()
        : _buildDesktopResizeHandle();
  }

  Widget _buildDesktopResizeHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => _onEnterHoverArea(),
      onExit: (event) => _onExitHoverArea(),
      child: GestureDetector(
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: ValueListenableBuilder(
          valueListenable: simpleTableContext.hoveringOnResizeHandle,
          builder: (context, hoveringOnResizeHandle, child) {
            // when reordering a column, the resize handle should not be shown
            final isSameRowIndex = hoveringOnResizeHandle?.columnIndex ==
                    widget.node.columnIndex &&
                !simpleTableContext.isReordering;
            return Opacity(
              opacity: isSameRowIndex ? 1.0 : 0.0,
              child: child,
            );
          },
          child: Container(
            height: double.infinity,
            width: SimpleTableConstants.resizeHandleWidth,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileResizeHandle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) {
        _onLongPressStart(details);
      },
      onLongPressMoveUpdate: (details) {
        _onLongPressMoveUpdate(details);
      },
      onLongPressEnd: (details) {
        _onLongPressEnd(details);
      },
      // onHorizontalDragStart: (details) {
      //   debugPrint('start');
      // },
      // onHorizontalDragUpdate: (details) {
      //   debugPrint('update');
      // },
      // onHorizontalDragEnd: (details) {
      //   debugPrint('end');
      // },
      child: Container(
        width: 14,
        color: Colors.red,
      ),
    );
  }

  void _onEnterHoverArea() {
    simpleTableContext.hoveringOnResizeHandle.value = widget.node;
  }

  void _onExitHoverArea() {
    Future.delayed(const Duration(milliseconds: 100), () {
      // the onExit event will be triggered before dragging started.
      // delay the hiding of the resize handle to avoid flickering.
      if (!isStartDragging) {
        simpleTableContext.hoveringOnResizeHandle.value = null;
      }
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    // disable the two-finger drag on trackpad
    if (details.kind == PointerDeviceKind.trackpad) {
      return;
    }

    isStartDragging = true;
  }

  void _onLongPressStart(LongPressStartDetails details) {
    isStartDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!isStartDragging) {
      return;
    }

    // only update the column width in memory,
    //  the actual update will be applied in _onHorizontalDragEnd
    context.read<EditorState>().updateColumnWidthInMemory(
          tableCellNode: widget.node,
          deltaX: details.delta.dx,
        );
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!isStartDragging) {
      return;
    }

    // only update the column width in memory,
    //  the actual update will be applied in _onHorizontalDragEnd
    context.read<EditorState>().updateColumnWidthInMemory(
          tableCellNode: widget.node,
          deltaX: details.offsetFromOrigin.dx - previousDx,
        );

    previousDx = details.offsetFromOrigin.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!isStartDragging) {
      return;
    }

    isStartDragging = false;
    context.read<SimpleTableContext>().hoveringOnResizeHandle.value = null;

    // apply the updated column width
    context.read<EditorState>().updateColumnWidth(
          tableCellNode: widget.node,
          width: widget.node.columnWidth,
        );
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!isStartDragging) {
      return;
    }

    isStartDragging = false;

    // apply the updated column width
    context.read<EditorState>().updateColumnWidth(
          tableCellNode: widget.node,
          width: widget.node.columnWidth,
        );

    previousDx = 0;
  }
}
