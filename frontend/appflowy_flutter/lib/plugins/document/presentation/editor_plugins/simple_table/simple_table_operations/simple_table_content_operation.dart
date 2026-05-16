import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_node_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableContentOperation on EditorState {
  /// Clear the content of the column at the given index.
  ///
  /// Before:
  /// Given column index: 0
  /// Row 1: | 0 | 1 | ← The content of these cells will be cleared
  /// Row 2: | 2 | 3 |
  ///
  /// Call this function with column index 0 will clear the first column of the table.
  ///
  /// After:
  /// Row 1: |   |   |
  /// Row 2: | 2 | 3 |
  Future<void> clearContentAtRowIndex({
    required Node tableNode,
    required int rowIndex,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (rowIndex < 0 || rowIndex >= tableNode.rowLength) {
      Log.warn('clear content in row: index out of range: $rowIndex');
      return;
    }

    Log.info('clear content in row: $rowIndex in table ${tableNode.id}');

    final transaction = this.transaction;

    final row = tableNode.children[rowIndex];
    for (var i = 0; i < row.children.length; i++) {
      final cell = row.children[i];
      transaction.insertNode(cell.path.next, simpleTableCellBlockNode());
      transaction.deleteNode(cell);
    }
    await apply(transaction);
  }

  /// Clear the content of the row at the given index.
  ///
  /// Before:
  /// Given row index: 1
  ///              ↓ The content of these cells will be cleared
  /// Row 1: | 0 | 1 |
  /// Row 2: | 2 | 3 |
  ///
  /// Call this function with row index 1 will clear the second row of the table.
  ///
  /// After:
  /// Row 1: | 0 |   |
  /// Row 2: | 2 |   |
  Future<void> clearContentAtColumnIndex({
    required Node tableNode,
    required int columnIndex,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (columnIndex < 0 || columnIndex >= tableNode.columnLength) {
      Log.warn('clear content in column: index out of range: $columnIndex');
      return;
    }

    Log.info('clear content in column: $columnIndex in table ${tableNode.id}');

    final transaction = this.transaction;
    for (var i = 0; i < tableNode.rowLength; i++) {
      final row = tableNode.children[i];
      final cell = columnIndex >= row.children.length
          ? row.children.last
          : row.children[columnIndex];
      transaction.insertNode(cell.path.next, simpleTableCellBlockNode());
      transaction.deleteNode(cell);
    }
    await apply(transaction);
  }

  /// Clear the content of the table.
  Future<void> clearAllContent({
    required Node tableNode,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    for (var i = 0; i < tableNode.rowLength; i++) {
      await clearContentAtRowIndex(tableNode: tableNode, rowIndex: i);
    }
  }

  /// Copy the selected column to the clipboard.
  ///
  /// If the [clearContent] is true, the content of the column will be cleared after
  /// copying.
  Future<ClipboardServiceData?> copyColumn({
    required Node tableNode,
    required int columnIndex,
    bool clearContent = false,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return null;
    }

    if (columnIndex < 0 || columnIndex >= tableNode.columnLength) {
      Log.warn('copy column: index out of range: $columnIndex');
      return null;
    }

    // the plain text content of the column
    final List<String> content = [];

    // the cells of the column
    final List<Node> cells = [];

    for (var i = 0; i < tableNode.rowLength; i++) {
      final row = tableNode.children[i];
      final cell = columnIndex >= row.children.length
          ? row.children.last
          : row.children[columnIndex];
      final startNode = cell.getFirstFocusableChild();
      final endNode = cell.getLastFocusableChild();
      if (startNode == null || endNode == null) {
        continue;
      }
      final plainText = getTextInSelection(
        Selection(
          start: Position(path: startNode.path),
          end: Position(
            path: endNode.path,
            offset: endNode.delta?.length ?? 0,
          ),
        ),
      );
      content.add(plainText.join('\n'));
      cells.add(cell.deepCopy());
    }

    final plainText = content.join('\n');
    final document = Document.blank()..insert([0], cells);

    if (clearContent) {
      await clearContentAtColumnIndex(
        tableNode: tableNode,
        columnIndex: columnIndex,
      );
    }

    return ClipboardServiceData(
      plainText: plainText,
      tableJson: jsonEncode(document.toJson()),
    );
  }

  /// Copy the selected row to the clipboard.
  ///
  /// If the [clearContent] is true, the content of the row will be cleared after
  /// copying.
  Future<ClipboardServiceData?> copyRow({
    required Node tableNode,
    required int rowIndex,
    bool clearContent = false,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return null;
    }

    if (rowIndex < 0 || rowIndex >= tableNode.rowLength) {
      Log.warn('copy row: index out of range: $rowIndex');
      return null;
    }

    // the plain text content of the row
    final List<String> content = [];

    // the cells of the row
    final List<Node> cells = [];

    final row = tableNode.children[rowIndex];
    for (var i = 0; i < row.children.length; i++) {
      final cell = row.children[i];
      final startNode = cell.getFirstFocusableChild();
      final endNode = cell.getLastFocusableChild();
      if (startNode == null || endNode == null) {
        continue;
      }
      final plainText = getTextInSelection(
        Selection(
          start: Position(path: startNode.path),
          end: Position(
            path: endNode.path,
            offset: endNode.delta?.length ?? 0,
          ),
        ),
      );
      content.add(plainText.join('\n'));
      cells.add(cell.deepCopy());
    }

    final plainText = content.join('\n');
    final document = Document.blank()..insert([0], cells);

    if (clearContent) {
      await clearContentAtRowIndex(
        tableNode: tableNode,
        rowIndex: rowIndex,
      );
    }

    return ClipboardServiceData(
      plainText: plainText,
      tableJson: jsonEncode(document.toJson()),
    );
  }

  /// Copy the selected table to the clipboard.
  Future<ClipboardServiceData?> copyTable({
    required Node tableNode,
    bool clearContent = false,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return null;
    }

    // the plain text content of the table
    final List<String> content = [];

    // the cells of the table
    final List<Node> cells = [];

    for (var i = 0; i < tableNode.rowLength; i++) {
      final row = tableNode.children[i];
      for (var j = 0; j < row.children.length; j++) {
        final cell = row.children[j];
        final startNode = cell.getFirstFocusableChild();
        final endNode = cell.getLastFocusableChild();
        if (startNode == null || endNode == null) {
          continue;
        }
        final plainText = getTextInSelection(
          Selection(
            start: Position(path: startNode.path),
            end: Position(
              path: endNode.path,
              offset: endNode.delta?.length ?? 0,
            ),
          ),
        );
        content.add(plainText.join('\n'));
        cells.add(cell.deepCopy());
      }
    }

    final plainText = content.join('\n');
    final document = Document.blank()..insert([0], cells);

    if (clearContent) {
      await clearAllContent(tableNode: tableNode);
    }

    return ClipboardServiceData(
      plainText: plainText,
      tableJson: jsonEncode(document.toJson()),
    );
  }

  /// Paste the clipboard content to the table column.
  Future<void> pasteColumn({
    required Node tableNode,
    required int columnIndex,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (columnIndex < 0 || columnIndex >= tableNode.columnLength) {
      Log.warn('paste column: index out of range: $columnIndex');
      return;
    }

    final clipboardData = await getIt<ClipboardService>().getData();
    final tableJson = clipboardData.tableJson;
    if (tableJson == null) {
      return;
    }

    try {
      final document = Document.fromJson(jsonDecode(tableJson));
      final cells = document.root.children;
      final transaction = this.transaction;
      for (var i = 0; i < tableNode.rowLength; i++) {
        final nodes = i < cells.length ? cells[i].children : <Node>[];
        final row = tableNode.children[i];
        final cell = columnIndex >= row.children.length
            ? row.children.last
            : row.children[columnIndex];
        if (nodes.isNotEmpty) {
          transaction.insertNodes(
            cell.path.child(0),
            nodes,
          );
          transaction.deleteNodes(cell.children);
        }
      }
      await apply(transaction);
    } catch (e) {
      Log.error('paste column: failed to paste: $e');
    }
  }

  /// Paste the clipboard content to the table row.
  Future<void> pasteRow({
    required Node tableNode,
    required int rowIndex,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (rowIndex < 0 || rowIndex >= tableNode.rowLength) {
      Log.warn('paste row: index out of range: $rowIndex');
      return;
    }

    final clipboardData = await getIt<ClipboardService>().getData();
    final tableJson = clipboardData.tableJson;
    if (tableJson == null) {
      return;
    }

    try {
      final document = Document.fromJson(jsonDecode(tableJson));
      final cells = document.root.children;
      final transaction = this.transaction;
      final row = tableNode.children[rowIndex];
      for (var i = 0; i < row.children.length; i++) {
        final nodes = i < cells.length ? cells[i].children : <Node>[];
        final cell = row.children[i];
        if (nodes.isNotEmpty) {
          transaction.insertNodes(
            cell.path.child(0),
            nodes,
          );
          transaction.deleteNodes(cell.children);
        }
      }
      await apply(transaction);
    } catch (e) {
      Log.error('paste row: failed to paste: $e');
    }
  }

  /// Paste the clipboard content to the table.
  Future<void> pasteTable({
    required Node tableNode,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    final clipboardData = await getIt<ClipboardService>().getData();
    final tableJson = clipboardData.tableJson;
    if (tableJson == null) {
      return;
    }

    try {
      final document = Document.fromJson(jsonDecode(tableJson));
      final cells = document.root.children;
      final transaction = this.transaction;
      for (var i = 0; i < tableNode.rowLength; i++) {
        final row = tableNode.children[i];
        for (var j = 0; j < row.children.length; j++) {
          final cell = row.children[j];
          final node = i + j < cells.length ? cells[i + j] : null;
          if (node != null && node.children.isNotEmpty) {
            transaction.insertNodes(
              cell.path.child(0),
              node.children,
            );
            transaction.deleteNodes(cell.children);
          }
        }
      }
      await apply(transaction);
    } catch (e) {
      Log.error('paste row: failed to paste: $e');
    }
  }
}
