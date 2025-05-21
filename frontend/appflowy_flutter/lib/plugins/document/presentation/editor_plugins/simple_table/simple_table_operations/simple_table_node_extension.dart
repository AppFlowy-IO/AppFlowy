import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_row_block_component.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

typedef TableCellPosition = (int, int);

enum TableAlign {
  left,
  center,
  right;

  static TableAlign fromString(String align) {
    return TableAlign.values.firstWhere(
      (e) => e.key.toLowerCase() == align.toLowerCase(),
      orElse: () => TableAlign.left,
    );
  }

  String get name => switch (this) {
        TableAlign.left => 'Left',
        TableAlign.center => 'Center',
        TableAlign.right => 'Right',
      };

  // The key used in the attributes of the table node.
  //
  // Example:
  //
  // attributes[SimpleTableBlockKeys.columnAligns] = {0: 'left', 1: 'center', 2: 'right'}
  String get key => switch (this) {
        TableAlign.left => 'left',
        TableAlign.center => 'center',
        TableAlign.right => 'right',
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

  TextAlign get textAlign => switch (this) {
        TableAlign.left => TextAlign.left,
        TableAlign.center => TextAlign.center,
        TableAlign.right => TextAlign.right,
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
    if (type == SimpleTableCellBlockKeys.type) {
      if (path.parent.isEmpty) {
        return -1;
      }
      return path.parent.last;
    } else if (type == SimpleTableRowBlockKeys.type) {
      return path.last;
    }
    return -1;
  }

  int get columnIndex {
    assert(type == SimpleTableCellBlockKeys.type);
    if (path.isEmpty) {
      return -1;
    }
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
        (e) => e.key == align,
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
        (e) => e.key == align,
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
    } else {
      return parent?.parentTableNode;
    }

    if (tableNode == null || tableNode.type != SimpleTableBlockKeys.type) {
      return null;
    }

    return tableNode;
  }

  Node? get parentTableCellNode {
    Node? tableCellNode;

    if (type == SimpleTableCellBlockKeys.type) {
      tableCellNode = this;
    } else {
      return parent?.parentTableCellNode;
    }

    return tableCellNode;
  }

  /// Whether the current node is in a table.
  bool get isInTable {
    return parentTableNode != null;
  }

  double get columnWidth {
    final parentTableNode = this.parentTableNode;

    if (parentTableNode == null) {
      return SimpleTableConstants.defaultColumnWidth;
    }

    try {
      final columnWidths =
          parentTableNode.attributes[SimpleTableBlockKeys.columnWidths];
      final width = columnWidths?[columnIndex.toString()] as Object?;
      if (width == null) {
        return SimpleTableConstants.defaultColumnWidth;
      }
      return width.toDouble(
        defaultValue: SimpleTableConstants.defaultColumnWidth,
      );
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
    return parentTableNode.isHeaderColumnEnabled &&
        parentTableCellNode?.columnIndex == 0;
  }

  /// Whether the current cell is bold in the column.
  ///
  /// Default is false.
  bool get isInBoldColumn {
    final parentTableCellNode = this.parentTableCellNode;
    final parentTableNode = this.parentTableNode;
    if (parentTableCellNode == null ||
        parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return false;
    }

    final columnIndex = parentTableCellNode.columnIndex;
    final columnBoldAttributes = parentTableNode.columnBoldAttributes;
    return columnBoldAttributes[columnIndex.toString()] ?? false;
  }

  /// Whether the current cell is bold in the row.
  ///
  /// Default is false.
  bool get isInBoldRow {
    final parentTableCellNode = this.parentTableCellNode;
    final parentTableNode = this.parentTableNode;
    if (parentTableCellNode == null ||
        parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return false;
    }

    final rowIndex = parentTableCellNode.rowIndex;
    final rowBoldAttributes = parentTableNode.rowBoldAttributes;
    return rowBoldAttributes[rowIndex.toString()] ?? false;
  }

  /// Get the text color of the current cell in the column.
  ///
  /// Default is null.
  String? get textColorInColumn {
    final parentTableCellNode = this.parentTableCellNode;
    final parentTableNode = this.parentTableNode;
    if (parentTableCellNode == null ||
        parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return null;
    }

    final columnIndex = parentTableCellNode.columnIndex;
    return parentTableNode.columnTextColors[columnIndex.toString()];
  }

  /// Get the text color of the current cell in the row.
  ///
  /// Default is null.
  String? get textColorInRow {
    final parentTableCellNode = this.parentTableCellNode;
    final parentTableNode = this.parentTableNode;
    if (parentTableCellNode == null ||
        parentTableNode == null ||
        parentTableNode.type != SimpleTableBlockKeys.type) {
      return null;
    }

    final rowIndex = parentTableCellNode.rowIndex;
    return parentTableNode.rowTextColors[rowIndex.toString()];
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
    return parentTableNode.isHeaderRowEnabled &&
        parentTableCellNode?.rowIndex == 0;
  }

  /// Get the row aligns.
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

  /// Get the row colors.
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

  /// Get the column colors.
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

  /// Get the column aligns.
  SimpleTableColumnAlignMap get columnAligns {
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

  /// Get the column widths.
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

  /// Get the column text colors
  SimpleTableColorMap get columnTextColors {
    final rawColumnTextColors =
        parentTableNode?.attributes[SimpleTableBlockKeys.columnTextColors];
    if (rawColumnTextColors == null) {
      return SimpleTableColorMap();
    }
    try {
      return SimpleTableColorMap.from(rawColumnTextColors);
    } catch (e) {
      Log.warn('get column text colors: $e');
      return SimpleTableColorMap();
    }
  }

  /// Get the row text colors
  SimpleTableColorMap get rowTextColors {
    final rawRowTextColors =
        parentTableNode?.attributes[SimpleTableBlockKeys.rowTextColors];
    if (rawRowTextColors == null) {
      return SimpleTableColorMap();
    }
    try {
      return SimpleTableColorMap.from(rawRowTextColors);
    } catch (e) {
      Log.warn('get row text colors: $e');
      return SimpleTableColorMap();
    }
  }

  /// Get the column bold attributes
  SimpleTableAttributeMap get columnBoldAttributes {
    final rawColumnBoldAttributes =
        parentTableNode?.attributes[SimpleTableBlockKeys.columnBoldAttributes];
    if (rawColumnBoldAttributes == null) {
      return SimpleTableAttributeMap();
    }
    try {
      return SimpleTableAttributeMap.from(rawColumnBoldAttributes);
    } catch (e) {
      Log.warn('get column bold attributes: $e');
      return SimpleTableAttributeMap();
    }
  }

  /// Get the row bold attributes
  SimpleTableAttributeMap get rowBoldAttributes {
    final rawRowBoldAttributes =
        parentTableNode?.attributes[SimpleTableBlockKeys.rowBoldAttributes];
    if (rawRowBoldAttributes == null) {
      return SimpleTableAttributeMap();
    }
    try {
      return SimpleTableAttributeMap.from(rawRowBoldAttributes);
    } catch (e) {
      Log.warn('get row bold attributes: $e');
      return SimpleTableAttributeMap();
    }
  }

  /// Get the width of the table.
  double get width {
    double currentColumnWidth = 0;
    for (var i = 0; i < columnLength; i++) {
      final columnWidth =
          columnWidths[i.toString()] ?? SimpleTableConstants.defaultColumnWidth;
      currentColumnWidth += columnWidth;
    }
    return currentColumnWidth;
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

  String? getTableCellContent({
    required int rowIndex,
    required int columnIndex,
  }) {
    final cell = getTableCellNode(rowIndex: rowIndex, columnIndex: columnIndex);
    if (cell == null) {
      return null;
    }
    final content = cell.children
        .map((e) => e.delta?.toPlainText())
        .where((e) => e != null)
        .join('\n');
    return content;
  }

  /// Return the first empty row in the table from bottom to top.
  ///
  /// Example:
  ///
  /// | A | B | C |
  /// |   |   |   |
  /// | E | F | G |
  /// | H | I | J |
  /// |   |   |   | <--- The first empty row is the row at index 3.
  /// |   |   |   |
  ///
  /// The first empty row is the row at index 3.
  (int, Node)? getFirstEmptyRowFromBottom() {
    assert(type == SimpleTableBlockKeys.type);

    if (type != SimpleTableBlockKeys.type) {
      return null;
    }

    (int, Node)? result;

    for (var i = children.length - 1; i >= 0; i--) {
      final row = children[i];

      // Check if all cells in this row are empty
      final hasContent = row.children.any((cell) {
        final content = getTableCellContent(
          rowIndex: i,
          columnIndex: row.children.indexOf(cell),
        );
        return content != null && content.isNotEmpty;
      });

      if (!hasContent) {
        if (result != null) {
          final (index, _) = result;
          if (i <= index) {
            result = (i, row);
          }
        } else {
          result = (i, row);
        }
      }
    }

    return result;
  }

  /// Return the first empty column in the table from right to left.
  ///
  /// Example:
  ///                  ↓ The first empty column is the column at index 3.
  /// | A | C |  | E |  |  |
  /// | B | D |  | F |  |  |
  ///
  /// The first empty column is the column at index 3.
  int? getFirstEmptyColumnFromRight() {
    assert(type == SimpleTableBlockKeys.type);

    if (type != SimpleTableBlockKeys.type) {
      return null;
    }

    int? result;

    for (var i = columnLength - 1; i >= 0; i--) {
      bool hasContent = false;
      for (var j = 0; j < rowLength; j++) {
        final content = getTableCellContent(
          rowIndex: j,
          columnIndex: i,
        );
        if (content != null && content.isNotEmpty) {
          hasContent = true;
        }
      }
      if (!hasContent) {
        if (result != null) {
          final index = result;
          if (i <= index) {
            result = i;
          }
        } else {
          result = i;
        }
      }
    }

    return result;
  }

  /// Get first focusable child in the table cell.
  ///
  /// If the current node is not a table cell node, it will return null.
  Node? getFirstFocusableChild() {
    if (children.isEmpty) {
      return this;
    }
    return children.first.getFirstFocusableChild();
  }

  /// Get last focusable child in the table cell.
  ///
  /// If the current node is not a table cell node, it will return null.
  Node? getLastFocusableChild() {
    if (children.isEmpty) {
      return this;
    }
    return children.last.getLastFocusableChild();
  }

  /// Get table align of column
  ///
  /// If one of the align is not same as the others, it will return TableAlign.left.
  TableAlign get allColumnAlign {
    final alignSet = columnAligns.values.toSet();
    if (alignSet.length == 1) {
      return TableAlign.fromString(alignSet.first);
    }
    return TableAlign.left;
  }

  /// Get table align of row
  ///
  /// If one of the align is not same as the others, it will return TableAlign.left.
  TableAlign get allRowAlign {
    final alignSet = rowAligns.values.toSet();
    if (alignSet.length == 1) {
      return TableAlign.fromString(alignSet.first);
    }
    return TableAlign.left;
  }

  /// Get table align of the table.
  ///
  /// If one of the align is not same as the others, it will return TableAlign.left.
  TableAlign get tableAlign {
    if (allColumnAlign != TableAlign.left) {
      return allColumnAlign;
    } else if (allRowAlign != TableAlign.left) {
      return allRowAlign;
    }
    return TableAlign.left;
  }
}

extension on Object {
  double toDouble({double defaultValue = 0}) {
    if (this is double) {
      return this as double;
    }
    if (this is String) {
      return double.tryParse(this as String) ?? defaultValue;
    }
    if (this is int) {
      return (this as int).toDouble();
    }
    return defaultValue;
  }
}
