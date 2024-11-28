import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_operations.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_table_test_helper.dart';

void main() {
  group('Simple table insert operation:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('add 2 rows in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      await editorState.addRowInTable(tableNode);
      await editorState.addRowInTable(tableNode);
      expect(tableNode.rowLength, 4);
      expect(tableNode.columnLength, 3);
    });

    test('add 2 columns in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      await editorState.addColumnInTable(tableNode);
      await editorState.addColumnInTable(tableNode);
      expect(tableNode.rowLength, 2);
      expect(tableNode.columnLength, 5);
    });

    test('add 2 rows and 2 columns in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      await editorState.addColumnAndRowInTable(tableNode);
      await editorState.addColumnAndRowInTable(tableNode);
      expect(tableNode.rowLength, 4);
      expect(tableNode.columnLength, 5);
    });

    test('insert a row at the first position in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      await editorState.insertRowInTable(tableNode, 0);
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 3);
    });

    test('insert a column at the first position in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      await editorState.insertColumnInTable(tableNode, 0);
      expect(tableNode.columnLength, 4);
      expect(tableNode.rowLength, 2);
    });
  });
}
