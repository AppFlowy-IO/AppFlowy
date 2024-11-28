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

    test('delete 2 rows in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      await editorState.deleteRowInTable(tableNode, 0);
      await editorState.deleteRowInTable(tableNode, 0);
      expect(tableNode.rowLength, 1);
      expect(tableNode.columnLength, 4);
    });

    test('delete 2 columns in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      await editorState.deleteColumnInTable(tableNode, 0);
      await editorState.deleteColumnInTable(tableNode, 0);
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 2);
    });

    test('delete a row and a column in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      await editorState.deleteColumnInTable(tableNode, 0);
      await editorState.deleteRowInTable(tableNode, 0);
      expect(tableNode.rowLength, 2);
      expect(tableNode.columnLength, 3);
    });
  });
}
