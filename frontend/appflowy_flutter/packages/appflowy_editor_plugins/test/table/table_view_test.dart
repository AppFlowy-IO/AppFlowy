import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import '../../../appflowy_editor/test/infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('table_view.dart', () {
    //TODO(zoli)
    //testWidgets('resize column', (tester) async {});

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

      var cell10 = tableNode.node.children.firstWhereOrNull((n) =>
          n.attributes['position']['col'] == 1 &&
          n.attributes['position']['row'] == 0)!;
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

      var cell10 = tableNode.node.children.firstWhereOrNull((n) =>
          n.attributes['position']['col'] == 1 &&
          n.attributes['position']['row'] == 0)!;
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
  });
}
