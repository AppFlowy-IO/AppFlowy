import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_action.dart';
import 'package:appflowy_editor_plugins/src/table/src/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import '../../../appflowy_editor/test/infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('table_view.dart', () {
    // TODO(zoli)
    // testWidgets('resize column', (tester) async {});

    testWidgets('row height changing base on cell height', (tester) async {
      final tableNode = TableNode.fromList([
        ['', ''],
        ['', '']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      var row0beforeHeight = tableNode.getRowHeight(0);
      var row1beforeHeight = tableNode.getRowHeight(1);
      expect(row0beforeHeight == row1beforeHeight, true);

      var cell10 = getCellNode(tableNode.node, 1, 0)!;
      await editor.updateSelection(
          Selection.single(path: cell10.childAtIndex(0)!.path, startOffset: 0));
      await editor.insertText(
          cell10.childAtIndex(0)! as TextNode, 'aaaaaaaaa', 0);
      tableNode.updateRowHeight(0);

      expect(tableNode.getRowHeight(0) != row0beforeHeight, true);
      expect(tableNode.getRowHeight(0), cell10.children.first.rect.height);
      expect(tableNode.getRowHeight(1), row1beforeHeight);
      expect(tableNode.getRowHeight(1) < tableNode.getRowHeight(0), true);
    });

    testWidgets('row height changing base on column width', (tester) async {
      final tableNode = TableNode.fromList([
        ['', ''],
        ['', '']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      var row0beforeHeight = tableNode.getRowHeight(0);
      var row1beforeHeight = tableNode.getRowHeight(1);
      expect(row0beforeHeight == row1beforeHeight, true);

      var cell10 = getCellNode(tableNode.node, 1, 0)!;
      await editor.updateSelection(
          Selection.single(path: cell10.childAtIndex(0)!.path, startOffset: 0));
      await editor.insertText(
          cell10.childAtIndex(0)! as TextNode, 'aaaaaaaaa', 0);
      tableNode.updateRowHeight(0);

      expect(tableNode.getRowHeight(0) != row0beforeHeight, true);
      expect(tableNode.getRowHeight(0), cell10.children.first.rect.height);

      tableNode.setColWidth(1, 302.5);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tableNode.getRowHeight(0), row0beforeHeight);
    });

    testWidgets('add column', (tester) async {
      var tableNode = TableNode.fromList([
        ['', ''],
        ['', '']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      final transaction = editor.editorState.transaction;
      addCol(tableNode.node, transaction);
      editor.editorState.apply(transaction);
      await tester.pump(const Duration(milliseconds: 100));
      tableNode = TableNode(node: tableNode.node);

      expect(tableNode.colsLen, 3);
      expect(
        tableNode.getCell(2, 1).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {
              "insert": "",
            }
          ]
        },
      );
      expect(tableNode.getColWidth(2), tableNode.config.colDefaultWidth);
    });

    testWidgets('add row', (tester) async {
      var tableNode = TableNode.fromList([
        ['', ''],
        ['', '']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      final transaction = editor.editorState.transaction;
      addRow(tableNode.node, transaction);
      editor.editorState.apply(transaction);
      await tester.pump(const Duration(milliseconds: 100));
      tableNode = TableNode(node: tableNode.node);

      expect(tableNode.rowsLen, 3);
      expect(
        tableNode.getCell(0, 2).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {
              "insert": "",
            }
          ]
        },
      );

      var cell12 = getCellNode(tableNode.node, 1, 2)!;
      expect(tableNode.getRowHeight(2), cell12.children.first.rect.height);
    });
  });
}
