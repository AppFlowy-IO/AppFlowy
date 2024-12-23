import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class SimpleTableBorderBuilder {
  SimpleTableBorderBuilder({
    required this.context,
    required this.simpleTableContext,
    required this.node,
  });

  final BuildContext context;
  final SimpleTableContext simpleTableContext;
  final Node node;

  /// Build the border for the cell.
  Border? buildBorder({
    bool isEditingCell = false,
  }) {
    if (SimpleTableConstants.borderType != SimpleTableBorderRenderType.cell) {
      return null;
    }

    // check if the cell is in the selected column
    final isCellInSelectedColumn =
        node.columnIndex == simpleTableContext.selectingColumn.value;

    // check if the cell is in the selected row
    final isCellInSelectedRow =
        node.rowIndex == simpleTableContext.selectingRow.value;

    final isReordering = simpleTableContext.isReordering &&
        (simpleTableContext.isReorderingColumn.value.$1 ||
            simpleTableContext.isReorderingRow.value.$1);

    final editorState = context.read<EditorState>();
    final editable = editorState.editable;

    if (!editable) {
      return buildCellBorder();
    } else if (isReordering) {
      return buildReorderingBorder();
    } else if (simpleTableContext.isSelectingTable.value) {
      return buildSelectingTableBorder();
    } else if (isCellInSelectedColumn) {
      return buildColumnHighlightBorder();
    } else if (isCellInSelectedRow) {
      return buildRowHighlightBorder();
    } else if (isEditingCell) {
      return buildEditingBorder();
    } else {
      return buildCellBorder();
    }
  }

  /// the column border means the `VERTICAL` border of the cell
  ///
  ///      ____
  /// | 1 | 2 |
  /// | 3 | 4 |
  ///     |___|
  ///
  /// the border wrapping the cell 2 and cell 4 is the column border
  Border buildColumnHighlightBorder() {
    return Border(
      left: _buildHighlightBorderSide(),
      right: _buildHighlightBorderSide(),
      top: node.rowIndex == 0
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
      bottom: node.rowIndex + 1 == node.parentTableNode?.rowLength
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
    );
  }

  /// the row border means the `HORIZONTAL` border of the cell
  ///
  ///  ________
  /// | 1 | 2 |
  /// |_______|
  /// | 3 | 4 |
  ///
  /// the border wrapping the cell 1 and cell 2 is the row border
  Border buildRowHighlightBorder() {
    return Border(
      top: _buildHighlightBorderSide(),
      bottom: _buildHighlightBorderSide(),
      left: node.columnIndex == 0
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
      right: node.columnIndex + 1 == node.parentTableNode?.columnLength
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
    );
  }

  /// Build the border for the reordering state.
  ///
  /// For example, when reordering a column, we should highlight the border of the
  /// current column we're hovering.
  Border buildReorderingBorder() {
    final isReorderingColumn = simpleTableContext.isReorderingColumn.value.$1;
    final isReorderingRow = simpleTableContext.isReorderingRow.value.$1;

    if (isReorderingColumn) {
      return _buildColumnReorderingBorder();
    } else if (isReorderingRow) {
      return _buildRowReorderingBorder();
    }

    return buildCellBorder();
  }

  /// Build the border for the cell without any state.
  Border buildCellBorder() {
    return Border(
      top: node.rowIndex == 0
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      bottom: node.rowIndex + 1 == node.parentTableNode?.rowLength
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      left: node.columnIndex == 0
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      right: node.columnIndex + 1 == node.parentTableNode?.columnLength
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
    );
  }

  /// Build the border for the editing state.
  Border buildEditingBorder() {
    return Border.all(
      color: Theme.of(context).colorScheme.primary,
      width: 2,
    );
  }

  /// Build the border for the selecting table state.
  Border buildSelectingTableBorder() {
    final rowIndex = node.rowIndex;
    final columnIndex = node.columnIndex;

    return Border(
      top:
          rowIndex == 0 ? _buildHighlightBorderSide() : _buildLightBorderSide(),
      bottom: rowIndex + 1 == node.parentTableNode?.rowLength
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
      left: columnIndex == 0
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
      right: columnIndex + 1 == node.parentTableNode?.columnLength
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
    );
  }

  Border _buildColumnReorderingBorder() {
    assert(simpleTableContext.isReordering);

    final isDraggingInCurrentColumn =
        simpleTableContext.isReorderingColumn.value.$2 == node.columnIndex;
    // if the dragging column is the current column, don't show the highlight border
    if (isDraggingInCurrentColumn) {
      return buildCellBorder();
    }

    bool isHitCurrentCell = false;

    if (UniversalPlatform.isDesktop) {
      // On desktop, we use the dragging column index to determine the highlight border
      // Check if the hovering table cell column index hit the current node column index
      isHitCurrentCell =
          simpleTableContext.hoveringTableCell.value?.columnIndex ==
              node.columnIndex;
    } else if (UniversalPlatform.isMobile) {
      // On mobile, we use the isReorderingHitIndex to determine the highlight border
      isHitCurrentCell =
          simpleTableContext.isReorderingHitIndex.value == node.columnIndex;
    }

    // if the hovering column is not the current column, don't show the highlight border
    if (!isHitCurrentCell) {
      return buildCellBorder();
    }

    // if the dragging column index is less than the current column index, show the
    // highlight border on the left side
    final isLeftSide =
        simpleTableContext.isReorderingColumn.value.$2 > node.columnIndex;
    // if the dragging column index is greater than the current column index, show
    // the highlight border on the right side
    final isRightSide =
        simpleTableContext.isReorderingColumn.value.$2 < node.columnIndex;

    return Border(
      top: node.rowIndex == 0
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      bottom: node.rowIndex + 1 == node.parentTableNode?.rowLength
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      left: isLeftSide ? _buildHighlightBorderSide() : _buildLightBorderSide(),
      right:
          isRightSide ? _buildHighlightBorderSide() : _buildLightBorderSide(),
    );
  }

  Border _buildRowReorderingBorder() {
    assert(simpleTableContext.isReordering);

    final isDraggingInCurrentRow =
        simpleTableContext.isReorderingRow.value.$2 == node.rowIndex;
    // if the dragging row is the current row, don't show the highlight border
    if (isDraggingInCurrentRow) {
      return buildCellBorder();
    }

    bool isHitCurrentCell = false;

    if (UniversalPlatform.isDesktop) {
      // On desktop, we use the dragging row index to determine the highlight border
      // Check if the hovering table cell row index hit the current node row index
      isHitCurrentCell =
          simpleTableContext.hoveringTableCell.value?.rowIndex == node.rowIndex;
    } else if (UniversalPlatform.isMobile) {
      // On mobile, we use the isReorderingHitIndex to determine the highlight border
      isHitCurrentCell =
          simpleTableContext.isReorderingHitIndex.value == node.rowIndex;
    }

    if (!isHitCurrentCell) {
      return buildCellBorder();
    }

    // For the row reordering, we only need to update the top and bottom border
    final isTopSide =
        simpleTableContext.isReorderingRow.value.$2 > node.rowIndex;
    final isBottomSide =
        simpleTableContext.isReorderingRow.value.$2 < node.rowIndex;

    return Border(
      top: isTopSide ? _buildHighlightBorderSide() : _buildLightBorderSide(),
      bottom:
          isBottomSide ? _buildHighlightBorderSide() : _buildLightBorderSide(),
      left: node.columnIndex == 0
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      right: node.columnIndex + 1 == node.parentTableNode?.columnLength
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
    );
  }

  BorderSide _buildHighlightBorderSide() {
    return BorderSide(
      color: Theme.of(context).colorScheme.primary,
      width: 2,
    );
  }

  BorderSide _buildLightBorderSide() {
    return BorderSide(
      color: context.simpleTableBorderColor,
      width: 0.5,
    );
  }

  BorderSide _buildDefaultBorderSide() {
    return BorderSide(
      color: context.simpleTableBorderColor,
    );
  }
}
