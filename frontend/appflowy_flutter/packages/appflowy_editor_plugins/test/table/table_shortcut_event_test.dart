import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/util.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import '../../../appflowy_editor/test/infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('table_shortcut_event.dart', () {
    testWidgets('enter key on middle cells', (tester) async {
      final tableNode = TableNode.fromList([
        ['', ''],
        ['', '']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      }, shortcutEvents: [
        enterInTableCell
      ]);
      await tester.pumpAndSettle();

      var cell00 = getCellNode(tableNode.node, 0, 0)!;

      await editor.updateSelection(
          Selection.single(path: cell00.childAtIndex(0)!.path, startOffset: 0));
      await editor.pressLogicKey(LogicalKeyboardKey.enter);

      var selection = editor.documentSelection!;
      var cell01 = getCellNode(tableNode.node, 0, 1)!;

      expect(selection.isCollapsed, true);
      expect(selection.start.path, cell01.childAtIndex(0)!.path);
      expect(selection.start.offset, 0);
    });

    testWidgets('enter key on last cell', (tester) async {
      final tableNode = TableNode.fromList([
        ['', ''],
        ['', '']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      }, shortcutEvents: [
        enterInTableCell
      ]);
      await tester.pumpAndSettle();

      var cell11 = getCellNode(tableNode.node, 1, 1)!;

      await editor.updateSelection(
          Selection.single(path: cell11.childAtIndex(0)!.path, startOffset: 0));
      await editor.pressLogicKey(LogicalKeyboardKey.enter);

      var selection = editor.documentSelection!;

      expect(selection.isCollapsed, true);
      expect(selection.start.path, editor.nodeAtPath([1])!.path);
      expect(selection.start.offset, 0);
      expect(editor.documentLength, 2);
    });

    testWidgets('backspace on beginning of cell', (tester) async {
      final tableNode = TableNode.fromList([
        ['', ''],
        ['', '']
      ]);
      final editor = tester.editor..insert(tableNode.node);

      await editor.startTesting(customBuilders: {
        kTableType: TableNodeWidgetBuilder(),
        kTableCellType: TableCellNodeWidgetBuilder()
      }, shortcutEvents: [
        enterInTableCell
      ]);
      await tester.pumpAndSettle();

      var cell10 = getCellNode(tableNode.node, 1, 0)!;

      await editor.updateSelection(
          Selection.single(path: cell10.childAtIndex(0)!.path, startOffset: 0));
      await editor.pressLogicKey(LogicalKeyboardKey.backspace);

      var selection = editor.documentSelection!;

      expect(selection.isCollapsed, true);
      expect(selection.start.path, cell10.childAtIndex(0)!.path);
      expect(selection.start.offset, 0);
    });

    // TODO(zoli)
    //testWidgets('backspace on multiple cell selection', (tester) async {});

    //testWidgets(
    //    'backspace on cell and after table node selection', (tester) async {});
  });
}
