import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableAddColumnHoverButton extends StatefulWidget {
  const SimpleTableAddColumnHoverButton({
    super.key,
    required this.editorState,
    required this.tableNode,
  });

  final EditorState editorState;
  final Node tableNode;

  @override
  State<SimpleTableAddColumnHoverButton> createState() =>
      _SimpleTableAddColumnHoverButtonState();
}

class _SimpleTableAddColumnHoverButtonState
    extends State<SimpleTableAddColumnHoverButton> {
  late final interceptorKey =
      'simple_table_add_column_hover_button_${widget.tableNode.id}';

  SelectionGestureInterceptor? interceptor;

  Offset? startDraggingOffset;
  int? initialColumnCount;

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

    return ValueListenableBuilder(
      valueListenable: context.read<SimpleTableContext>().isHoveringOnTableArea,
      builder: (context, isHoveringOnTableArea, _) {
        return ValueListenableBuilder(
          valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
          builder: (context, hoveringTableCell, _) {
            bool shouldShow = isHoveringOnTableArea;
            if (hoveringTableCell != null &&
                SimpleTableConstants.enableHoveringLogicV2) {
              shouldShow = hoveringTableCell.columnIndex + 1 ==
                  hoveringTableCell.columnLength;
            }
            return Positioned(
              top: SimpleTableConstants.tableHitTestTopPadding -
                  SimpleTableConstants.cellBorderWidth,
              bottom: SimpleTableConstants.addColumnButtonBottomPadding,
              right: 0,
              child: Opacity(
                opacity: shouldShow ? 1.0 : 0.0,
                child: SimpleTableAddColumnButton(
                  onTap: () {
                    // cancel the selection to avoid flashing the selection
                    widget.editorState.selection = null;

                    widget.editorState.addColumnInTable(widget.tableNode);
                  },
                  onHorizontalDragStart: (details) {
                    context.read<SimpleTableContext>().isDraggingColumn = true;
                    startDraggingOffset = details.globalPosition;
                    initialColumnCount = widget.tableNode.columnLength;
                  },
                  onHorizontalDragEnd: (details) {
                    context.read<SimpleTableContext>().isDraggingColumn = false;
                  },
                  onHorizontalDragUpdate: (details) {
                    _insertColumnInMemory(details);
                  },
                ),
              ),
            );
          },
        );
      },
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

  void _insertColumnInMemory(DragUpdateDetails details) {
    if (!SimpleTableConstants.enableDragToExpandTable) {
      return;
    }

    if (startDraggingOffset == null || initialColumnCount == null) {
      return;
    }

    // calculate the horizontal offset from the start dragging offset
    final horizontalOffset =
        details.globalPosition.dx - startDraggingOffset!.dx;

    const columnWidth = SimpleTableConstants.defaultColumnWidth;
    final columnDelta = (horizontalOffset / columnWidth).round();

    // if the change is less than 1 column, skip the operation
    if (columnDelta.abs() < 1) {
      return;
    }

    final firstEmptyColumnFromRight =
        widget.tableNode.getFirstEmptyColumnFromRight();
    if (firstEmptyColumnFromRight == null) {
      return;
    }

    final currentColumnCount = widget.tableNode.columnLength;
    final targetColumnCount = initialColumnCount! + columnDelta;

    // There're 3 cases that we don't want to proceed:
    // 1. targetColumnCount < 0: the table at least has 1 column
    // 2. targetColumnCount == currentColumnCount: the table has no change
    // 3. targetColumnCount <= initialColumnCount: the table has less columns than the initial column count
    if (targetColumnCount <= 0 ||
        targetColumnCount == currentColumnCount ||
        targetColumnCount <= firstEmptyColumnFromRight) {
      return;
    }

    if (targetColumnCount > currentColumnCount) {
      widget.editorState.insertColumnInTable(
        widget.tableNode,
        targetColumnCount,
        inMemoryUpdate: true,
      );
    } else {
      widget.editorState.deleteColumnInTable(
        widget.tableNode,
        targetColumnCount,
        inMemoryUpdate: true,
      );
    }
  }
}

class SimpleTableAddColumnButton extends StatelessWidget {
  const SimpleTableAddColumnButton({
    super.key,
    this.onTap,
    required this.onHorizontalDragStart,
    required this.onHorizontalDragEnd,
    required this.onHorizontalDragUpdate,
  });

  final VoidCallback? onTap;
  final void Function(DragStartDetails) onHorizontalDragStart;
  final void Function(DragEndDetails) onHorizontalDragEnd;
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_simpleTable_clickToAddNewColumn.tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onHorizontalDragStart: onHorizontalDragStart,
        onHorizontalDragEnd: onHorizontalDragEnd,
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: SimpleTableConstants.addColumnButtonWidth,
            margin: const EdgeInsets.symmetric(
              horizontal: SimpleTableConstants.addColumnButtonPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SimpleTableConstants.addColumnButtonRadius,
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
