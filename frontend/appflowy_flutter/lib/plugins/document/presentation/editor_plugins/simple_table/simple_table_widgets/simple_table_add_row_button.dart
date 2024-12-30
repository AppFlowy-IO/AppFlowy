import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableAddRowHoverButton extends StatefulWidget {
  const SimpleTableAddRowHoverButton({
    super.key,
    required this.editorState,
    required this.tableNode,
  });

  final EditorState editorState;
  final Node tableNode;

  @override
  State<SimpleTableAddRowHoverButton> createState() =>
      _SimpleTableAddRowHoverButtonState();
}

class _SimpleTableAddRowHoverButtonState
    extends State<SimpleTableAddRowHoverButton> {
  late final interceptorKey =
      'simple_table_add_row_hover_button_${widget.tableNode.id}';

  SelectionGestureInterceptor? interceptor;

  Offset? startDraggingOffset;
  int? initialRowCount;

  @override
  void initState() {
    super.initState();

    interceptor = SelectionGestureInterceptor(
      key: interceptorKey,
      canTap: (details) => !_isTapInBounds(details.globalPosition),
    );
    widget.editorState.service.selectionService
        .registerGestureInterceptor(interceptor!);
  }

  @override
  void dispose() {
    widget.editorState.service.selectionService.unregisterGestureInterceptor(
      interceptorKey,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.tableNode.type == SimpleTableBlockKeys.type);

    if (widget.tableNode.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    final simpleTableContext = context.read<SimpleTableContext>();
    return ValueListenableBuilder(
      valueListenable: simpleTableContext.isHoveringOnTableArea,
      builder: (context, isHoveringOnTableArea, child) {
        return ValueListenableBuilder(
          valueListenable: simpleTableContext.hoveringTableCell,
          builder: (context, hoveringTableCell, _) {
            bool shouldShow = isHoveringOnTableArea;
            if (hoveringTableCell != null &&
                SimpleTableConstants.enableHoveringLogicV2) {
              shouldShow =
                  hoveringTableCell.rowIndex + 1 == hoveringTableCell.rowLength;
            }
            if (simpleTableContext.isDraggingRow) {
              shouldShow = true;
            }
            return shouldShow ? child! : const SizedBox.shrink();
          },
        );
      },
      child: Positioned(
        bottom: 2 * SimpleTableConstants.addRowButtonPadding,
        left: SimpleTableConstants.tableLeftPadding -
            SimpleTableConstants.cellBorderWidth,
        right: SimpleTableConstants.addRowButtonRightPadding,
        child: SimpleTableAddRowButton(
          onTap: () {
            // cancel the selection to avoid flashing the selection
            widget.editorState.selection = null;

            widget.editorState.addRowInTable(
              widget.tableNode,
            );
          },
          onVerticalDragStart: (details) {
            context.read<SimpleTableContext>().isDraggingRow = true;
            startDraggingOffset = details.globalPosition;
            initialRowCount = widget.tableNode.children.length;
          },
          onVerticalDragEnd: (details) {
            context.read<SimpleTableContext>().isDraggingRow = false;
          },
          onVerticalDragUpdate: (details) {
            _insertRowInMemory(details);
          },
        ),
      ),
    );
  }

  bool _isTapInBounds(Offset offset) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return false;
    }

    final localPosition = renderBox.globalToLocal(offset);
    final result = renderBox.paintBounds.contains(localPosition);

    return result;
  }

  void _insertRowInMemory(DragUpdateDetails details) {
    if (!SimpleTableConstants.enableDragToExpandTable) {
      return;
    }

    if (startDraggingOffset == null || initialRowCount == null) {
      return;
    }

    // calculate the vertical offset from the start dragging offset
    final verticalOffset = details.globalPosition.dy - startDraggingOffset!.dy;

    const rowHeight = SimpleTableConstants.defaultRowHeight;
    final rowDelta = (verticalOffset / rowHeight).round();

    // if the change is less than 1 row, skip the operation
    if (rowDelta.abs() < 1) {
      return;
    }

    final firstEmptyRowFromBottom =
        widget.tableNode.getFirstEmptyRowFromBottom();
    if (firstEmptyRowFromBottom == null) {
      return;
    }

    final currentRowCount = widget.tableNode.children.length;
    final targetRowCount = initialRowCount! + rowDelta;

    // There're 3 cases that we don't want to proceed:
    // 1. targetRowCount < 0: the table at least has 1 row
    // 2. targetRowCount == currentRowCount: the table has no change
    // 3. targetRowCount <= initialRowCount: the table has less rows than the initial row count
    if (targetRowCount <= 0 ||
        targetRowCount == currentRowCount ||
        targetRowCount <= firstEmptyRowFromBottom.$1) {
      return;
    }

    if (targetRowCount > currentRowCount) {
      widget.editorState.insertRowInTable(
        widget.tableNode,
        targetRowCount,
        inMemoryUpdate: true,
      );
    } else {
      widget.editorState.deleteRowInTable(
        widget.tableNode,
        targetRowCount,
        inMemoryUpdate: true,
      );
    }
  }
}

class SimpleTableAddRowButton extends StatelessWidget {
  const SimpleTableAddRowButton({
    super.key,
    this.onTap,
    required this.onVerticalDragStart,
    required this.onVerticalDragEnd,
    required this.onVerticalDragUpdate,
  });

  final VoidCallback? onTap;
  final void Function(DragStartDetails) onVerticalDragStart;
  final void Function(DragEndDetails) onVerticalDragEnd;
  final void Function(DragUpdateDetails) onVerticalDragUpdate;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_simpleTable_clickToAddNewRow.tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragEnd: onVerticalDragEnd,
        onVerticalDragUpdate: onVerticalDragUpdate,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: SimpleTableConstants.addRowButtonHeight,
            margin: const EdgeInsets.symmetric(
              vertical: SimpleTableConstants.addColumnButtonPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SimpleTableConstants.addRowButtonRadius,
              ),
              color: context.simpleTableMoreActionBackgroundColor,
            ),
            child: const FlowySvg(
              FlowySvgs.add_s,
            ),
          ),
        ),
      ),
    );
  }
}
