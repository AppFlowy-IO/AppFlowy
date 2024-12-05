import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_table_test_helper.dart';

void main() {
  group('Simple table reorder operation:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('reorder column from index 1 to index 2', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 4,
        columnCount: 3,
        contentBuilder: (rowIndex, columnIndex) =>
            'cell $rowIndex-$columnIndex',
      );
      await editorState.reorderColumn(tableNode, fromIndex: 1, toIndex: 2);
      expect(tableNode.columnLength, 3);
      expect(tableNode.rowLength, 4);
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 0),
        'cell 0-0',
      );
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 1),
        'cell 0-2',
      );
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 2),
        'cell 0-1',
      );
    });

    test('reorder column from index 2 to index 0', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 4,
        columnCount: 3,
        contentBuilder: (rowIndex, columnIndex) =>
            'cell $rowIndex-$columnIndex',
      );
      await editorState.reorderColumn(tableNode, fromIndex: 2, toIndex: 0);
      expect(tableNode.columnLength, 3);
      expect(tableNode.rowLength, 4);
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 0),
        'cell 0-2',
      );
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 1),
        'cell 0-0',
      );
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 2),
        'cell 0-1',
      );
    });

    test('reorder column with same index', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 4,
        columnCount: 3,
        contentBuilder: (rowIndex, columnIndex) =>
            'cell $rowIndex-$columnIndex',
      );
      await editorState.reorderColumn(tableNode, fromIndex: 1, toIndex: 1);
      expect(tableNode.columnLength, 3);
      expect(tableNode.rowLength, 4);
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 0),
        'cell 0-0',
      );
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 1),
        'cell 0-1',
      );
      expect(
        tableNode.getTableCellContent(rowIndex: 0, columnIndex: 2),
        'cell 0-2',
      );
    });

    test('reorder column from index 0 to index 2 with align/color attributes',
        () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 4,
        columnCount: 3,
        contentBuilder: (rowIndex, columnIndex) =>
            'cell $rowIndex-$columnIndex',
      );

      // before reorder
      // Column 0: align: right, color: 0xFF0000, width: 100
      // Column 1: align: center, color: 0x00FF00, width: 150
      // Column 2: align: left, color: 0x0000FF, width: 200
      await updateTableColumnAttributes(
        editorState,
        tableNode,
        columnIndex: 0,
        align: TableAlign.right,
        color: '#FF0000',
        width: 100,
      );
      await updateTableColumnAttributes(
        editorState,
        tableNode,
        columnIndex: 1,
        align: TableAlign.center,
        color: '#00FF00',
        width: 150,
      );
      await updateTableColumnAttributes(
        editorState,
        tableNode,
        columnIndex: 2,
        align: TableAlign.left,
        color: '#0000FF',
        width: 200,
      );

      // after reorder
      // Column 0: align: center, color: 0x00FF00, width: 150
      // Column 1: align: left, color: 0x0000FF, width: 200
      // Column 2: align: right, color: 0xFF0000, width: 100
      await editorState.reorderColumn(tableNode, fromIndex: 0, toIndex: 2);
      expect(tableNode.columnLength, 3);
      expect(tableNode.rowLength, 4);

      expect(tableNode.columnAligns, {
        "0": TableAlign.center.key,
        "1": TableAlign.left.key,
        "2": TableAlign.right.key,
      });
      expect(tableNode.columnColors, {
        "0": '#00FF00',
        "1": '#0000FF',
        "2": '#FF0000',
      });
      expect(tableNode.columnWidths, {
        "0": 150,
        "1": 200,
        "2": 100,
      });
    });
  });
}
