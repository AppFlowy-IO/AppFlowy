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

    test('duplicate a row with background and align (1)', () async {
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
      await editorState.updateRowAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.rowAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.duplicateRowInTable(tableNode, 1);
      expect(tableCellNode.rowColors, {
        '1': '0xFF0000FF',
        '2': '0xFF0000FF',
      });
      expect(tableNode.rowAligns, {
        '1': TableAlign.center.key,
        '2': TableAlign.center.key,
      });
    });

    test('duplicate a row with background and align (2)', () async {
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
      await editorState.updateRowAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.rowAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.duplicateRowInTable(tableNode, 2);
      expect(tableCellNode.rowColors, {
        '1': '0xFF0000FF',
      });
      expect(tableNode.rowAligns, {
        '1': TableAlign.center.key,
      });
    });

    test('duplicate a column with background and align (1)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // duplicate the column 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 0, columnIndex: 1);
      await editorState.updateColumnBackgroundColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      await editorState.updateColumnAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.columnColors, {
        '1': '0xFF0000FF',
      });
      expect(tableNode.columnAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.duplicateColumnInTable(tableNode, 1);
      expect(tableCellNode.columnColors, {
        '1': '0xFF0000FF',
        '2': '0xFF0000FF',
      });
      expect(tableNode.columnAligns, {
        '1': TableAlign.center.key,
        '2': TableAlign.center.key,
      });
    });

    test('duplicate a column with background and align (2)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // duplicate the column 1
      final tableCellNode =
          tableNode.getTableCellNode(rowIndex: 0, columnIndex: 1);
      await editorState.updateColumnBackgroundColor(
        tableCellNode: tableCellNode!,
        color: '0xFF0000FF',
      );
      await editorState.updateColumnAlign(
        tableCellNode: tableCellNode,
        align: TableAlign.center,
      );
      expect(tableNode.columnColors, {
        '1': '0xFF0000FF',
      });
      expect(tableNode.columnAligns, {
        '1': TableAlign.center.key,
      });
      await editorState.duplicateColumnInTable(tableNode, 2);
      expect(tableCellNode.columnColors, {
        '1': '0xFF0000FF',
      });
      expect(tableNode.columnAligns, {
        '1': TableAlign.center.key,
      });
    });

    test('duplicate a column with text color & bold style (1)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // duplicate the column 1
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
      await editorState.duplicateColumnInTable(tableNode, 1);
      expect(tableNode.columnTextColors, {
        '1': '0xFF0000FF',
        '2': '0xFF0000FF',
      });
      expect(tableNode.columnBoldAttributes, {
        '1': true,
        '2': true,
      });
    });

    test('duplicate a column with text color & bold style (2)', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
      );
      // duplicate the column 1
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
      await editorState.duplicateColumnInTable(tableNode, 0);
      expect(tableNode.columnTextColors, {
        '2': '0xFF0000FF',
      });
      expect(tableNode.columnBoldAttributes, {
        '2': true,
      });
    });
  });
}
