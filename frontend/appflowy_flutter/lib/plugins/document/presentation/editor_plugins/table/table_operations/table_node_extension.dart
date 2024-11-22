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
}
