import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
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

      for (var i = 0; i < tableNode.columnLength; i++) {
        final tableCellNode = tableNode.getTableCellNode(
          rowIndex: 0,
          columnIndex: i,
        );
        await editorState.updateColumnWidth(
          tableCellNode: tableCellNode!,
          width: 100,
        );
      }
      expect(tableNode.columnWidths, {
        '0': 100,
        '1': 100,
        '2': 100,
      });

      // set the width less than the minimum column width
      for (var i = 0; i < tableNode.columnLength; i++) {
        final tableCellNode = tableNode.getTableCellNode(
          rowIndex: 0,
          columnIndex: i,
        );
        await editorState.updateColumnWidth(
          tableCellNode: tableCellNode!,
          width: -1000,
        );
      }
      expect(tableNode.columnWidths, {
        '0': SimpleTableConstants.minimumColumnWidth,
        '1': SimpleTableConstants.minimumColumnWidth,
        '2': SimpleTableConstants.minimumColumnWidth,
      });
    });

    test('update column align', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );
      for (var i = 0; i < tableNode.columnLength; i++) {
        final tableCellNode = tableNode.getTableCellNode(
          rowIndex: 0,
          columnIndex: i,
        );
        await editorState.updateColumnAlign(
          tableCellNode: tableCellNode!,
          align: TableAlign.center,
        );
      }
      expect(tableNode.columnAligns, {
        '0': TableAlign.center.key,
        '1': TableAlign.center.key,
        '2': TableAlign.center.key,
      });
    });

    test('update row align', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );

      for (var i = 0; i < tableNode.rowLength; i++) {
        final tableCellNode = tableNode.getTableCellNode(
          rowIndex: i,
          columnIndex: 0,
        );
        await editorState.updateRowAlign(
          tableCellNode: tableCellNode!,
          align: TableAlign.center,
        );
      }

      expect(tableNode.rowAligns, {
        '0': TableAlign.center.key,
        '1': TableAlign.center.key,
      });
    });

    test('update column background color', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );

      for (var i = 0; i < tableNode.columnLength; i++) {
        final tableCellNode = tableNode.getTableCellNode(
          rowIndex: 0,
          columnIndex: i,
        );
        await editorState.updateColumnBackgroundColor(
          tableCellNode: tableCellNode!,
          color: '0xFF0000FF',
        );
      }
      expect(tableNode.columnColors, {
        '0': '0xFF0000FF',
        '1': '0xFF0000FF',
        '2': '0xFF0000FF',
      });
    });

    test('update row background color', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );

      for (var i = 0; i < tableNode.rowLength; i++) {
        final tableCellNode = tableNode.getTableCellNode(
          rowIndex: i,
          columnIndex: 0,
        );
        await editorState.updateRowBackgroundColor(
          tableCellNode: tableCellNode!,
          color: '0xFF0000FF',
        );
      }

      expect(tableNode.rowColors, {
        '0': '0xFF0000FF',
        '1': '0xFF0000FF',
      });
    });

    test('update table align', () async {
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
      );

      for (final align in [
        TableAlign.center,
        TableAlign.right,
        TableAlign.left,
      ]) {
        await editorState.updateTableAlign(
          tableNode: tableNode,
          align: align,
        );
        expect(tableNode.tableAlign, align);
      }
    });
  });
}
