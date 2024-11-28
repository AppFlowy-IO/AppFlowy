import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_operations.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_table_test_helper.dart';

void main() {
  group('Simple table delete operation:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('duplicate a row', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      await editorState.duplicateRowInTable(tableNode, 0);
      expect(tableNode.rowLength, 4);
      expect(tableNode.columnLength, 4);
    });

    test('duplicate a column', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      await editorState.duplicateColumnInTable(tableNode, 0);
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 5);
    });

    test('duplicate a row with background', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // duplicate the row 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 1, columnIndex: 0);
      await editorState.updateRowBackgroundColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      expect(tableCellNode.rowColors, {
        '1': '0xFF0000FF',
      });
      await editorState.duplicateRowInTable(tableNode, 1);
      expect(tableCellNode.rowColors, {
        '1': '0xFF0000FF',
        '2': '0xFF0000FF',
      });
    });
  });
}
