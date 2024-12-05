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
  });
}
