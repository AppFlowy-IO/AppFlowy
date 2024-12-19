import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_map_operation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:universal_platform/universal_platform.dart';

extension TableOptionOperation on EditorState {
  /// Update the column width of the table in memory. Call this function when dragging the table column.
  ///
  /// The deltaX is the change of the column width.
  Future<void> updateColumnWidthInMemory({
    required Node tableCellNode,
    required double deltaX,
  }) async {
    // Disable in mobile
    if (UniversalPlatform.isMobile) {
      return;
    }

    assert(tableCellNode.type == SimpleTableCellBlockKeys.type);

    if (tableCellNode.type != SimpleTableCellBlockKeys.type) {
      return;
    }

    // when dragging the table column, we need to update the column width in memory.
    // so that the table can render the column with the new width.
    // but don't need to persist to the database immediately.
    // only persist to the database when the drag is completed.
    final columnIndex = tableCellNode.columnIndex;
    final parentTableNode = tableCellNode.parentTableNode;
    if (parentTableNode == null) {
      Log.warn('parent table node is null');
      return;
    }

    final width = tableCellNode.columnWidth + deltaX;

    try {
      final columnWidths =
          parentTableNode.attributes[SimpleTableBlockKeys.columnWidths] ??
              SimpleTableColumnWidthMap();
      final newAttributes = {
        ...parentTableNode.attributes,
        SimpleTableBlockKeys.columnWidths: {
          ...columnWidths,
          columnIndex.toString(): width.clamp(
            SimpleTableConstants.minimumColumnWidth,
            double.infinity,
          ),
        },
      };

      parentTableNode.updateAttributes(newAttributes);
    } catch (e) {
      Log.warn('update column width in memory: $e');
    }
  }

  /// Update the column width of the table. Call this function after the drag is completed.
  Future<void> updateColumnWidth({
    required Node tableCellNode,
    required double width,
  }) async {
    // Disable in mobile
    if (UniversalPlatform.isMobile) {
      return;
    }

    assert(tableCellNode.type == SimpleTableCellBlockKeys.type);

    if (tableCellNode.type != SimpleTableCellBlockKeys.type) {
      return;
    }

    final columnIndex = tableCellNode.columnIndex;
    final parentTableNode = tableCellNode.parentTableNode;
    if (parentTableNode == null) {
      Log.warn('parent table node is null');
      return;
    }

    final transaction = this.transaction;
    final columnWidths =
        parentTableNode.attributes[SimpleTableBlockKeys.columnWidths] ??
            SimpleTableColumnWidthMap();
    transaction.updateNode(parentTableNode, {
      SimpleTableBlockKeys.columnWidths: {
        ...columnWidths,
        columnIndex.toString(): width.clamp(
          SimpleTableConstants.minimumColumnWidth,
          double.infinity,
        ),
      },
      // reset the distribute column widths evenly flag
      SimpleTableBlockKeys.distributeColumnWidthsEvenly: false,
    });
    await apply(transaction);
  }

  /// Update the align of the column at the index where the table cell node is located.
  ///
  /// Before:
  /// Given table cell node:
  /// Row 1: | 0 | 1 |
  /// Row 2: |2  |3  | ← This column will be updated
  ///
  /// Call this function will update the align of the column where the table cell node is located.
  ///
  /// After:
  /// Row 1: | 0 | 1 |
  /// Row 2: | 2 | 3 | ← This column is updated, texts are aligned to the center
  Future<void> updateColumnAlign({
    required Node tableCellNode,
    required TableAlign align,
  }) async {
    assert(tableCellNode.type == SimpleTableCellBlockKeys.type);

    final parentTableNode = tableCellNode.parentTableNode;

    if (parentTableNode == null) {
      Log.warn('parent table node is null');
      return;
    }

    final transaction = this.transaction;
    final columnIndex = tableCellNode.columnIndex;
    final attributes = parentTableNode.attributes.mergeValues(
      SimpleTableBlockKeys.columnAligns,
      parentTableNode.columnAligns,
      duplicatedEntry: MapEntry(columnIndex.toString(), align.key),
    );
    transaction.updateNode(parentTableNode, attributes);
    await apply(transaction);
  }

  /// Update the align of the row at the index where the table cell node is located.
  ///
  /// Before:
  /// Given table cell node:
  ///              ↓ This row will be updated
  /// Row 1: | 0 |1  |
  /// Row 2: | 2 |3  |
  ///
  /// Call this function will update the align of the row where the table cell node is located.
  ///
  /// After:
  ///              ↓ This row is updated, texts are aligned to the center
  /// Row 1: | 0 | 1 |
  /// Row 2: | 2 | 3 |
  Future<void> updateRowAlign({
    required Node tableCellNode,
    required TableAlign align,
  }) async {
    assert(tableCellNode.type == SimpleTableCellBlockKeys.type);

    final parentTableNode = tableCellNode.parentTableNode;

    if (parentTableNode == null) {
      Log.warn('parent table node is null');
      return;
    }

    final transaction = this.transaction;
    final rowIndex = tableCellNode.rowIndex;
    final attributes = parentTableNode.attributes.mergeValues(
      SimpleTableBlockKeys.rowAligns,
      parentTableNode.rowAligns,
      duplicatedEntry: MapEntry(rowIndex.toString(), align.key),
    );
    transaction.updateNode(parentTableNode, attributes);
    await apply(transaction);
  }

  /// Update the background color of the column at the index where the table cell node is located.
  Future<void> updateColumnBackgroundColor({
    required Node tableCellNode,
    required String color,
  }) async {
    assert(tableCellNode.type == SimpleTableCellBlockKeys.type);

    final parentTableNode = tableCellNode.parentTableNode;

    if (parentTableNode == null) {
      Log.warn('parent table node is null');
      return;
    }

    final columnIndex = tableCellNode.columnIndex;

    Log.info(
      'update column background color: $color at column $columnIndex in table ${parentTableNode.id}',
    );

    final transaction = this.transaction;
    final attributes = parentTableNode.attributes.mergeValues(
      SimpleTableBlockKeys.columnColors,
      parentTableNode.columnColors,
      duplicatedEntry: MapEntry(columnIndex.toString(), color),
    );
    transaction.updateNode(parentTableNode, attributes);
    await apply(transaction);
  }

  /// Update the background color of the row at the index where the table cell node is located.
  Future<void> updateRowBackgroundColor({
    required Node tableCellNode,
    required String color,
  }) async {
    assert(tableCellNode.type == SimpleTableCellBlockKeys.type);

    final parentTableNode = tableCellNode.parentTableNode;

    if (parentTableNode == null) {
      Log.warn('parent table node is null');
      return;
    }

    final rowIndex = tableCellNode.rowIndex;

    Log.info(
      'update row background color: $color at row $rowIndex in table ${parentTableNode.id}',
    );

    final transaction = this.transaction;

    final attributes = parentTableNode.attributes.mergeValues(
      SimpleTableBlockKeys.rowColors,
      parentTableNode.rowColors,
      duplicatedEntry: MapEntry(rowIndex.toString(), color),
    );
    transaction.updateNode(parentTableNode, attributes);
    await apply(transaction);
  }

  /// Set the column width of the table to the page width.
  ///
  /// Example:
  ///
  /// Before:
  /// | 0 |   1   |
  /// | 3 |   4   |
  ///
  /// After:
  /// |  0  |    1    | <- the column's width will be expanded based on the percentage of the page width
  /// |  3  |    4    |
  ///
  /// This function will update the table width.
  Future<void> setColumnWidthToPageWidth({
    required Node tableNode,
  }) async {
    // Disable in mobile
    if (UniversalPlatform.isMobile) {
      return;
    }

    final columnLength = tableNode.columnLength;
    double? pageWidth = tableNode.renderBox?.size.width;
    if (pageWidth == null) {
      Log.warn('table node render box is null');
      return;
    }
    pageWidth -= SimpleTableConstants.tablePageOffset;

    final transaction = this.transaction;
    final columnWidths = tableNode.columnWidths;
    final ratio = pageWidth / tableNode.width;
    for (var i = 0; i < columnLength; i++) {
      final columnWidth =
          columnWidths[i.toString()] ?? SimpleTableConstants.defaultColumnWidth;
      columnWidths[i.toString()] = (columnWidth * ratio).clamp(
        SimpleTableConstants.minimumColumnWidth,
        double.infinity,
      );
    }
    transaction.updateNode(tableNode, {
      SimpleTableBlockKeys.columnWidths: columnWidths,
      SimpleTableBlockKeys.distributeColumnWidthsEvenly: false,
    });
    await apply(transaction);
  }

  /// Distribute the column width of the table to the page width.
  ///
  /// Example:
  ///
  /// Before:
  /// Before:
  /// | 0 |   1   |
  /// | 3 |   4   |
  ///
  /// After:
  /// |  0  |  1  | <- the column's width will be expanded based on the percentage of the page width
  /// |  3  |  4  |
  ///
  /// This function will not update table width.
  Future<void> distributeColumnWidthToPageWidth({
    required Node tableNode,
  }) async {
    // Disable in mobile
    if (UniversalPlatform.isMobile) {
      return;
    }

    final columnLength = tableNode.columnLength;
    final tableWidth = tableNode.width;
    final columnWidth = (tableWidth / columnLength).clamp(
      SimpleTableConstants.minimumColumnWidth,
      double.infinity,
    );
    final transaction = this.transaction;
    final columnWidths = tableNode.columnWidths;
    for (var i = 0; i < columnLength; i++) {
      columnWidths[i.toString()] = columnWidth;
    }
    transaction.updateNode(tableNode, {
      SimpleTableBlockKeys.columnWidths: columnWidths,
      SimpleTableBlockKeys.distributeColumnWidthsEvenly: true,
    });
    await apply(transaction);
  }
}
