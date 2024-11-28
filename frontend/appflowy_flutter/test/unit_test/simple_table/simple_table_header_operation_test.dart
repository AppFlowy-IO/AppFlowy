import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_operations.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_table_test_helper.dart';

void main() {
  group('Simple table header operation:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('enable header column in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      // default is not header column
      expect(tableNode.isHeaderColumnEnabled, false);
      await editorState.toggleEnableHeaderColumn(tableNode, true);
      expect(tableNode.isHeaderColumnEnabled, true);
      await editorState.toggleEnableHeaderColumn(tableNode, false);
      expect(tableNode.isHeaderColumnEnabled, false);
      expect(tableNode.rowLength, 2);
      expect(tableNode.columnLength, 3);
    });

    test('enable header row in table', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      // default is not header row
      expect(tableNode.isHeaderRowEnabled, false);
      await editorState.toggleEnableHeaderRow(tableNode, true);
      expect(tableNode.isHeaderRowEnabled, true);
      await editorState.toggleEnableHeaderRow(tableNode, false);
      expect(tableNode.isHeaderRowEnabled, false);
      expect(tableNode.rowLength, 2);
      expect(tableNode.columnLength, 3);
    });
  });
}
