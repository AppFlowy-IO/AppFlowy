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

  group('table_action.dart', () {
    testWidgets('remove column', (tester) async {
      var tableNode = TableNode.fromList([
        ['1', '2'],
        ['3', '4']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      final transaction = editor.editorState.transaction;
      removeCol(tableNode.node, 0, transaction);
      editor.editorState.apply(transaction);
      await tester.pump(const Duration(milliseconds: 100));
      tableNode = TableNode(node: tableNode.node);

      expect(tableNode.colsLen, 1);
      expect(
        tableNode.getCell(0, 0).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {
              "insert": "3",
            }
          ]
        },
      );
    });

    testWidgets('remove row', (tester) async {
      var tableNode = TableNode.fromList([
        ['1', '2'],
        ['3', '4']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      final transaction = editor.editorState.transaction;
      removeRow(tableNode.node, 0, transaction);
      editor.editorState.apply(transaction);
      await tester.pump(const Duration(milliseconds: 100));
      tableNode = TableNode(node: tableNode.node);

      expect(tableNode.rowsLen, 1);
      expect(
        tableNode.getCell(0, 0).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {
              "insert": "2",
            }
          ]
        },
      );
    });
  });
}
