import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../appflowy_editor/test/infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('table_node_widget.dart', () {
    testWidgets('render table node', (tester) async {
      final tableNode = TableNode.fromList([
        ['']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      expect(editor.documentLength, 1);
      expect(find.byType(TableNodeWidget), findsOneWidget);
      expect(tableNode.colsLen, 1);
      expect(tableNode.rowsLen, 1);
      expect(tableNode.node.children.length, 1);
      expect(tableNode.node.children.first.children.first is TextNode, true);
    });

    testWidgets('table delete action', (tester) async {
      final table = TableNode.fromList([
        ['']
      ]);
      final editor = tester.editor..insert(table.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      expect(editor.documentLength, 1);
      expect(find.byType(TableNodeWidget), findsOneWidget);

      final tableNode = editor.document.nodeAtPath([0]);
      expect(editor.runAction(1, tableNode!), true);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TableNodeWidget), findsNothing);
    });

    testWidgets('table duplicate action', (tester) async {
      final table = TableNode.fromList([
        ['']
      ]);
      final editor = tester.editor..insert(table.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      });
      await tester.pumpAndSettle();

      expect(find.byType(TableNodeWidget), findsOneWidget);

      final tableNode = editor.document.nodeAtPath([0]);
      expect(editor.runAction(0, tableNode!), true);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TableNodeWidget), findsNWidgets(2));
    });
  });
}
