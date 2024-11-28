import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_row_block_component.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

typedef TableCellPosition = (int, int);

enum TableAlign {
  left,
  center,
  right;

  String get name => switch (this) {
        TableAlign.left => 'Left',
        TableAlign.center => 'Center',
        TableAlign.right => 'Right',
      };

  FlowySvgData get leftIconSvg => switch (this) {
        TableAlign.left => FlowySvgs.table_align_left_s,
        TableAlign.center => FlowySvgs.table_align_center_s,
        TableAlign.right => FlowySvgs.table_align_right_s,
      };

  Alignment get alignment => switch (this) {
        TableAlign.left => Alignment.topLeft,
        TableAlign.center => Alignment.topCenter,
        TableAlign.right => Alignment.topRight,
      };
}

extension TableNodeExtension on Node {
  /// The number of rows in the table.
  ///
  /// The acceptable node is a table node, table row node or table cell node.
  ///
  /// Example:
  ///
  /// Row 1: |   |   |   |
  /// Row 2: |   |   |   |
  ///
  /// The row length is 2.
  int get rowLength {
    final parentTableNode = this.parentTableNode;

    if (parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return -1;
    }

    return parentTableNode.children.length;
  }

  /// The number of rows in the table.
  ///
  /// The acceptable node is a table node, table row node or table cell node.
  ///
  /// Example:
  ///
  /// Row 1: |   |   |   |
  /// Row 2: |   |   |   |
  ///
  /// The column length is 3.
  int get columnLength {
    final parentTableNode = this.parentTableNode;

    if (parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return -1;
    }

    return parentTableNode.children.firstOrNull?.children.length ?? 0;
  }

  TableCellPosition get cellPosition {
    assert(type == SimpleTableCellBlockKeys.type);
    return (rowIndex, columnIndex);
  }

  int get rowIndex {
    assert(type == SimpleTableCellBlockKeys.type);
    return path.parent.last;
  }

  int get columnIndex {
    assert(type == SimpleTableCellBlockKeys.type);
    return path.last;
  }

  bool get isHeaderColumnEnabled {
    try {
      return parentTableNode
              ?.attributes[SimpleTableBlockKeys.enableHeaderColumn] ??
          false;
    } catch (e) {
      Log.warn('get is header column enabled: $e');
      return false;
    }
  }

  bool get isHeaderRowEnabled {
    try {
      return parentTableNode
              ?.attributes[SimpleTableBlockKeys.enableHeaderRow] ??
          false;
    } catch (e) {
      Log.warn('get is header row enabled: $e');
      return false;
    }
  }

  TableAlign get rowAlign {
    final parentTableNode = this.parentTableNode;

    if (parentTableNode == null) {
      return TableAlign.left;
    }

    try {
      final rowAligns =
          parentTableNode.attributes[SimpleTableBlockKeys.rowAligns];
      final align = rowAligns?[rowIndex.toString()];
      return TableAlign.values.firstWhere(
        (e) => e.name == align,
        orElse: () => TableAlign.left,
      );
    } catch (e) {
      Log.warn('get row align: $e');
      return TableAlign.left;
    }
  }

  TableAlign get columnAlign {
    final parentTableNode = this.parentTableNode;

    if (parentTableNode == null) {
      return TableAlign.left;
    }

    try {
      final columnAligns =
          parentTableNode.attributes[SimpleTableBlockKeys.columnAligns];
      final align = columnAligns?[columnIndex.toString()];
      return TableAlign.values.firstWhere(
        (e) => e.name == align,
        orElse: () => TableAlign.left,
      );
    } catch (e) {
      Log.warn('get column align: $e');
      return TableAlign.left;
    }
  }

  Node? get parentTableNode {
    Node? tableNode;

    if (type == SimpleTableBlockKeys.type) {
      tableNode = this;
    } else if (type == SimpleTableRowBlockKeys.type) {
      tableNode = parent;
    } else if (type == SimpleTableCellBlockKeys.type) {
      tableNode = parent?.parent;
    }

    if (tableNode == null || tableNode.type != SimpleTableBlockKeys.type) {
      return null;
    }

    return tableNode;
  }

  double get columnWidth {
    final parentTableNode = this.parentTableNode;

    if (parentTableNode == null) {
      return SimpleTableConstants.defaultColumnWidth;
    }

    try {
      final columnWidths =
          parentTableNode.attributes[SimpleTableBlockKeys.columnWidths];
      final width = columnWidths?[columnIndex.toString()];
      return width ?? SimpleTableConstants.defaultColumnWidth;
    } catch (e) {
      Log.warn('get column width: $e');
      return SimpleTableConstants.defaultColumnWidth;
    }
  }

  /// Build the row color.
  ///
  /// Default is null.
  Color? buildRowColor(BuildContext context) {
    try {
      final rawRowColors =
          parentTableNode?.attributes[SimpleTableBlockKeys.rowColors];
      if (rawRowColors == null) {
        return null;
      }
      final color = rawRowColors[rowIndex.toString()];
      if (color == null) {
        return null;
      }
      return buildEditorCustomizedColor(context, this, color);
    } catch (e) {
      Log.warn('get row color: $e');
      return null;
    }
  }

  /// Build the column color.
  ///
  /// Default is null.
  Color? buildColumnColor(BuildContext context) {
    try {
      final columnColors =
          parentTableNode?.attributes[SimpleTableBlockKeys.columnColors];
      if (columnColors == null) {
        return null;
      }
      final color = columnColors[columnIndex.toString()];
      if (color == null) {
        return null;
      }
      return buildEditorCustomizedColor(context, this, color);
    } catch (e) {
      Log.warn('get column color: $e');
      return null;
    }
  }

  /// Whether the current node is in the header column.
  ///
  /// Default is false.
  bool get isInHeaderColumn {
    final parentTableNode = parent?.parentTableNode;
    if (parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return false;
    }
    return parentTableNode.isHeaderColumnEnabled && parent?.columnIndex == 0;
  }

  /// Whether the current node is in the header row.
  ///
  /// Default is false.
  bool get isInHeaderRow {
    final parentTableNode = parent?.parentTableNode;
    if (parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return false;
    }
    return parentTableNode.isHeaderRowEnabled && parent?.rowIndex == 0;
  }

  SimpleTableRowAlignMap get rowAligns {
    final rawRowAligns =
        parentTableNode?.attributes[SimpleTableBlockKeys.rowAligns];
    if (rawRowAligns == null) {
      return SimpleTableRowAlignMap();
    }
    try {
      return SimpleTableRowAlignMap.from(rawRowAligns);
    } catch (e) {
      Log.warn('get row aligns: $e');
      return SimpleTableRowAlignMap();
    }
  }

  SimpleTableColorMap get rowColors {
    final rawRowColors =
        parentTableNode?.attributes[SimpleTableBlockKeys.rowColors];
    if (rawRowColors == null) {
      return SimpleTableColorMap();
    }
    try {
      return SimpleTableColorMap.from(rawRowColors);
    } catch (e) {
      Log.warn('get row colors: $e');
      return SimpleTableColorMap();
    }
  }

  SimpleTableColorMap get columnColors {
    final rawColumnColors =
        parentTableNode?.attributes[SimpleTableBlockKeys.columnColors];
    if (rawColumnColors == null) {
      return SimpleTableColorMap();
    }
    try {
      return SimpleTableColorMap.from(rawColumnColors);
    } catch (e) {
      Log.warn('get column colors: $e');
      return SimpleTableColorMap();
    }
  }

  SimpleTableRowAlignMap get columnAligns {
    final rawColumnAligns =
        parentTableNode?.attributes[SimpleTableBlockKeys.columnAligns];
    if (rawColumnAligns == null) {
      return SimpleTableRowAlignMap();
    }
    try {
      return SimpleTableRowAlignMap.from(rawColumnAligns);
    } catch (e) {
      Log.warn('get column aligns: $e');
      return SimpleTableRowAlignMap();
    }
  }

  SimpleTableColumnWidthMap get columnWidths {
    final rawColumnWidths =
        parentTableNode?.attributes[SimpleTableBlockKeys.columnWidths];
    if (rawColumnWidths == null) {
      return SimpleTableColumnWidthMap();
    }
    try {
      return SimpleTableColumnWidthMap.from(rawColumnWidths);
    } catch (e) {
      Log.warn('get column widths: $e');
      return SimpleTableColumnWidthMap();
    }
  }

  /// Get the previous cell in the same column. If the row index is 0, it will return the same cell.
  Node? getPreviousCellInSameColumn() {
    assert(type == SimpleTableCellBlockKeys.type);
    final parentTableNode = this.parentTableNode;
    if (parentTableNode == null) {
      return null;
    }

    final columnIndex = this.columnIndex;
    final rowIndex = this.rowIndex;

    if (rowIndex == 0) {
      return this;
    }

    final previousColumn = parentTableNode.children[rowIndex - 1];
    final previousCell = previousColumn.children[columnIndex];
    return previousCell;
  }

  /// Get the next cell in the same column. If the row index is the last row, it will return the same cell.
  Node? getNextCellInSameColumn() {
    assert(type == SimpleTableCellBlockKeys.type);
    final parentTableNode = this.parentTableNode;
    if (parentTableNode == null) {
      return null;
    }

    final columnIndex = this.columnIndex;
    final rowIndex = this.rowIndex;

    if (rowIndex == parentTableNode.rowLength - 1) {
      return this;
    }

    final nextColumn = parentTableNode.children[rowIndex + 1];
    final nextCell = nextColumn.children[columnIndex];
    return nextCell;
  }

  /// Get the right cell in the same row. If the column index is the last column, it will return the same cell.
  Node? getNextCellInSameRow() {
    assert(type == SimpleTableCellBlockKeys.type);
    final parentTableNode = this.parentTableNode;
    if (parentTableNode == null) {
      return null;
    }

    final columnIndex = this.columnIndex;
    final rowIndex = this.rowIndex;

    // the last cell
    if (columnIndex == parentTableNode.columnLength - 1 &&
        rowIndex == parentTableNode.rowLength - 1) {
      return this;
    }

    if (columnIndex == parentTableNode.columnLength - 1) {
      final nextRow = parentTableNode.children[rowIndex + 1];
      final nextCell = nextRow.children.first;
      return nextCell;
    }

    final nextColumn = parentTableNode.children[rowIndex];
    final nextCell = nextColumn.children[columnIndex + 1];
    return nextCell;
  }

  /// Get the previous cell in the same row. If the column index is 0, it will return the same cell.
  Node? getPreviousCellInSameRow() {
    assert(type == SimpleTableCellBlockKeys.type);
    final parentTableNode = this.parentTableNode;
    if (parentTableNode == null) {
      return null;
    }

    final columnIndex = this.columnIndex;
    final rowIndex = this.rowIndex;

    if (columnIndex == 0 && rowIndex == 0) {
      return this;
    }

    if (columnIndex == 0) {
      final previousRow = parentTableNode.children[rowIndex - 1];
      final previousCell = previousRow.children.last;
      return previousCell;
    }

    final previousColumn = parentTableNode.children[rowIndex];
    final previousCell = previousColumn.children[columnIndex - 1];
    return previousCell;
  }

  /// Get the previous focusable sibling.
  ///
  /// If the current node is the first child of its parent, it will return itself.
  Node? getPreviousFocusableSibling() {
    final parent = this.parent;
    if (parent == null) {
      return null;
    }
    final parentTableNode = this.parentTableNode;
    if (parentTableNode == null) {
      return null;
    }
    if (parentTableNode.path == [0]) {
      return this;
    }
    final previous = parentTableNode.previous;
    if (previous == null) {
      return null;
    }
    var children = previous.children;
    if (children.isEmpty) {
      return previous;
    }
    while (children.isNotEmpty) {
      children = children.last.children;
    }
    return children.lastWhere((c) => c.delta != null);
  }

  /// Get the next focusable sibling.
  ///
  /// If the current node is the last child of its parent, it will return itself.
  Node? getNextFocusableSibling() {
    final next = this.next;
    if (next == null) {
      return null;
    }
    return next;
  }

  /// Is the last cell in the table.
  bool get isLastCellInTable {
    return columnIndex + 1 == parentTableNode?.columnLength &&
        rowIndex + 1 == parentTableNode?.rowLength;
  }

  /// Is the first cell in the table.
  bool get isFirstCellInTable {
    return columnIndex == 0 && rowIndex == 0;
  }

  /// Get the table cell node by the row index and column index.
  ///
  /// If the current node is not a table cell node, it will return null.
  /// Or if the row index or column index is out of range, it will return null.
  Node? getTableCellNode({
    required int rowIndex,
    required int columnIndex,
  }) {
    assert(type == SimpleTableBlockKeys.type);

    if (type != SimpleTableBlockKeys.type) {
      return null;
    }

    if (rowIndex < 0 || rowIndex >= rowLength) {
      return null;
    }

    if (columnIndex < 0 || columnIndex >= columnLength) {
      return null;
    }

    return children[rowIndex].children[columnIndex];
  }
}
