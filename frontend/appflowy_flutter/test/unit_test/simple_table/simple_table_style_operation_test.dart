import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_operations.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_table_test_helper.dart';

void main() {
  group('Simple table style operation:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('update column width in memory', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      // check the default column width
      expect(tableNode.columnWidths, isEmpty);
      final tableCellNode = tableNode.getTableCellNode(
        rowIndex: 0,
        columnIndex: 0,
      );
      await editorState.updateColumnWidthInMemory(
        tableCellNode: tableCellNode!,
        deltaX: 100,
      );
      expect(tableNode.columnWidths, {
        '0': SimpleTableConstants.defaultColumnWidth + 100,
      });

      // set the width less than the minimum column width
      await editorState.updateColumnWidthInMemory(
        tableCellNode: tableCellNode,
        deltaX: -1000,
      );
      expect(tableNode.columnWidths, {
        '0': SimpleTableConstants.minimumColumnWidth,
      });
    });

    test('update column width', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      expect(tableNode.columnWidths, isEmpty);

      final tableCellNode = tableNode.getTableCellNode(
        rowIndex: 0,
        columnIndex: 0,
      );
      await editorState.updateColumnWidth(
        tableCellNode: tableCellNode!,
        width: 100,
      );
      expect(tableNode.columnWidths, {
        '0': 100,
      });

      // set the width less than the minimum column width
      await editorState.updateColumnWidth(
        tableCellNode: tableCellNode,
        width: -1000,
      );
      expect(tableNode.columnWidths, {
        '0': SimpleTableConstants.minimumColumnWidth,
      });
    });
  });
}
