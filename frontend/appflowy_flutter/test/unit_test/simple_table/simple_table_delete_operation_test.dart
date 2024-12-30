import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
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

    test('delete a row with background and align (1)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // delete the row 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 1, columnIndex: 0);
      await editorState.updateRowBackgroundColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      expect(tableCellNode.rowColors, {
        '1': '0xFF0000FF',
      });
      await editorState.updateRowAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.rowAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.deleteRowInTable(tableNode, 1);
      expect(tableNode.rowLength, 2);
      expect(tableNode.columnLength, 4);
      expect(tableCellNode.rowColors, {});
      expect(tableNode.rowAligns, {});
    });

    test('delete a row with background and align (2)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // delete the row 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 1, columnIndex: 0);
      await editorState.updateRowBackgroundColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      expect(tableCellNode.rowColors, {
        '1': '0xFF0000FF',
      });
      await editorState.updateRowAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.rowAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.deleteRowInTable(tableNode, 0);
      expect(tableNode.rowLength, 2);
      expect(tableNode.columnLength, 4);
      expect(tableCellNode.rowColors, {
        '0': '0xFF0000FF',
      });
      expect(tableNode.rowAligns, {
        '0': TableAlign.center.key,
      });
    });

    test('delete a column with background and align (1)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // delete the column 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 0, columnIndex: 1);
      await editorState.updateColumnBackgroundColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      expect(tableCellNode.columnColors, {
        '1': '0xFF0000FF',
      });
      await editorState.updateColumnAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.columnAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.deleteColumnInTable(tableNode, 1);
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 3);
      expect(tableCellNode.columnColors, {});
      expect(tableNode.columnAligns, {});
    });

    test('delete a column with background (2)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // delete the column 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 0, columnIndex: 1);
      await editorState.updateColumnBackgroundColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      expect(tableCellNode.columnColors, {
        '1': '0xFF0000FF',
      });
      await editorState.updateColumnAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.columnAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.deleteColumnInTable(tableNode, 0);
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 3);
      expect(tableCellNode.columnColors, {
        '0': '0xFF0000FF',
      });
      expect(tableNode.columnAligns, {
        '0': TableAlign.center.key,
      });
    });

    test('delete a column with text color & bold style (1)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // delete the column 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 0, columnIndex: 1);
      await editorState.updateColumnTextColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      await editorState.toggleColumnBoldAttribute(
        tableCellNode: tableCellNode,
        isBold: true,
      );
      expect(tableNode.columnTextColors, {
        '1': '0xFF0000FF',
      });
      expect(tableNode.columnBoldAttributes, {
        '1': true,
      });
      await editorState.deleteColumnInTable(tableNode, 0);
      expect(tableNode.columnTextColors, {
        '0': '0xFF0000FF',
      });
      expect(tableNode.columnBoldAttributes, {
        '0': true,
      });
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 3);
    });

    test('delete a column with text color & bold style (2)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // delete the column 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 0, columnIndex: 1);
      await editorState.updateColumnTextColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      await editorState.toggleColumnBoldAttribute(
        tableCellNode: tableCellNode,
        isBold: true,
      );
      expect(tableNode.columnTextColors, {
        '1': '0xFF0000FF',
      });
      expect(tableNode.columnBoldAttributes, {
        '1': true,
      });
      await editorState.deleteColumnInTable(tableNode, 1);
      expect(tableNode.columnTextColors, {});
      expect(tableNode.columnBoldAttributes, {});
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 3);
    });
  });
}
