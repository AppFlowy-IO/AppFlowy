import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_map_operation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableOptionOperation on EditorState {
  /// Update the column width of the table in memory. Call this function when dragging the table column.
  ///
  /// The deltaX is the change of the column width.
  Future<void> updateColumnWidthInMemory({
    required Node tableCellNode,
    required double deltaX,
  }) async {
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
    assert(tableCellNode.type == SimpleTableCellBlockKeys.type);

    if (tableCellNode.type != SimpleTableCellBlockKeys.type) {
      return;
    }

    final cellPosition = tableCellNode.cellPosition;
    final rowIndex = cellPosition.$2;
    final parentTableNode = tableCellNode.parentTableNode;
    if (parentTableNode == null) {
      Log.warn('parent table node is null');
      return;
    }

    final width = tableCellNode.columnWidth;
    final transaction = this.transaction;
    transaction.updateNode(parentTableNode, {
      SimpleTableBlockKeys.columnWidths: {
        ...parentTableNode.attributes[SimpleTableBlockKeys.columnWidths],
        rowIndex.toString(): width.clamp(
          SimpleTableConstants.minimumColumnWidth,
          double.infinity,
        ),
      },
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
      duplicatedEntry: MapEntry(columnIndex.toString(), align.name),
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
      duplicatedEntry: MapEntry(rowIndex.toString(), align.name),
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
}
