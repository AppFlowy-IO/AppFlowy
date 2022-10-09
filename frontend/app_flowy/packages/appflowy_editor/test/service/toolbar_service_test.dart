import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item_widget.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import '../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('toolbar_service.dart', () {
    testWidgets('Test toolbar service in multi text selection', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      final selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [1], offset: text.length),
      );
      await editor.updateSelection(selection);

      expect(find.byType(ToolbarWidget), findsOneWidget);

      // no link item
      final item = defaultToolbarItems
          .where((item) => item.id == 'appflowy.toolbar.link')
          .first;
      final finder = find.byType(ToolbarItemWidget);

      expect(
        tester
            .widgetList<ToolbarItemWidget>(finder)
            .toList(growable: false)
            .where((element) => element.item.id == item.id)
            .isEmpty,
        true,
      );
    });

    testWidgets(
        'Test toolbar service in single text selection with BuiltInAttributeKey.partialStyleKeys',
        (tester) async {
      final attributes = BuiltInAttributeKey.partialStyleKeys
          .fold<Attributes>({}, (previousValue, element) {
        if (element == BuiltInAttributeKey.backgroundColor) {
          previousValue[element] = '0x6000BCF0';
        } else if (element == BuiltInAttributeKey.href) {
          previousValue[element] = 'appflowy.io';
        } else {
          previousValue[element] = true;
        }
        return previousValue;
      });

      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(
          null,
          delta: Delta(operations: [
            TextInsert(text),
            TextInsert(text, attributes: attributes),
            TextInsert(text),
          ]),
        );
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: text.length),
      );
      expect(find.byType(ToolbarWidget), findsOneWidget);

      void testHighlight(bool expectedValue) {
        for (final styleKey in BuiltInAttributeKey.partialStyleKeys) {
          var key = styleKey;
          if (styleKey == BuiltInAttributeKey.backgroundColor) {
            key = 'highlight';
          } else if (styleKey == BuiltInAttributeKey.href) {
            key = 'link';
          } else {
            continue;
          }
          final itemWidget = _itemWidgetForId(tester, 'appflowy.toolbar.$key');
          expect(itemWidget.isHighlight, expectedValue);
        }
      }

      await editor.updateSelection(
        Selection.single(path: [1], startOffset: 0, endOffset: text.length * 2),
      );
      testHighlight(false);

      await editor.updateSelection(
        Selection.single(
          path: [1],
          startOffset: text.length,
          endOffset: text.length * 2,
        ),
      );
      testHighlight(true);

      await editor.updateSelection(
        Selection.single(
          path: [1],
          startOffset: text.length + 2,
          endOffset: text.length * 2 - 2,
        ),
      );
      testHighlight(true);
    });

    testWidgets(
        'Test toolbar service in single text selection with BuiltInAttributeKey.globalStyleKeys',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';

      final editor = tester.editor
        ..insertTextNode(text, attributes: {
          BuiltInAttributeKey.subtype: BuiltInAttributeKey.heading,
          BuiltInAttributeKey.heading: BuiltInAttributeKey.h1,
        })
        ..insertTextNode(
          text,
          attributes: {BuiltInAttributeKey.subtype: BuiltInAttributeKey.quote},
        )
        ..insertTextNode(
          text,
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList
          },
        );
      await editor.startTesting();

      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: text.length),
      );
      expect(find.byType(ToolbarWidget), findsOneWidget);
      var itemWidget = _itemWidgetForId(tester, 'appflowy.toolbar.h1');
      expect(itemWidget.isHighlight, true);

      await editor.updateSelection(
        Selection.single(path: [1], startOffset: 0, endOffset: text.length),
      );
      expect(find.byType(ToolbarWidget), findsOneWidget);
      itemWidget = _itemWidgetForId(tester, 'appflowy.toolbar.quote');
      expect(itemWidget.isHighlight, true);

      await editor.updateSelection(
        Selection.single(path: [2], startOffset: 0, endOffset: text.length),
      );
      expect(find.byType(ToolbarWidget), findsOneWidget);
      itemWidget = _itemWidgetForId(tester, 'appflowy.toolbar.bulleted_list');
      expect(itemWidget.isHighlight, true);
    });

    testWidgets('Test toolbar service in multi text selection', (tester) async {
      const text = 'Welcome to Appflowy 😁';

      /// [h1][bold] Welcome to Appflowy 😁
      /// [EmptyLine]
      /// Welcome to Appflowy 😁
      final editor = tester.editor
        ..insertTextNode(
          null,
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.heading,
            BuiltInAttributeKey.heading: BuiltInAttributeKey.h1,
          },
          delta: Delta(operations: [
            TextInsert(text, attributes: {
              BuiltInAttributeKey.bold: true,
            })
          ]),
        )
        ..insertTextNode(null)
        ..insertTextNode(text);
      await editor.startTesting();

      await editor.updateSelection(
        Selection.single(path: [2], startOffset: text.length, endOffset: 0),
      );
      expect(find.byType(ToolbarWidget), findsOneWidget);
      expect(
        _itemWidgetForId(tester, 'appflowy.toolbar.h1').isHighlight,
        false,
      );
      expect(
        _itemWidgetForId(tester, 'appflowy.toolbar.bold').isHighlight,
        false,
      );

      await editor.updateSelection(
        Selection(
          start: Position(path: [2], offset: text.length),
          end: Position(path: [1], offset: 0),
        ),
      );
      expect(find.byType(ToolbarWidget), findsOneWidget);
      expect(
        _itemWidgetForId(tester, 'appflowy.toolbar.bold').isHighlight,
        false,
      );

      await editor.updateSelection(
        Selection(
          start: Position(path: [2], offset: text.length),
          end: Position(path: [0], offset: 0),
        ),
      );
      expect(find.byType(ToolbarWidget), findsOneWidget);
      expect(
        _itemWidgetForId(tester, 'appflowy.toolbar.bold').isHighlight,
        false,
      );
    });
  });
}

ToolbarItemWidget _itemWidgetForId(WidgetTester tester, String id) {
  final finder = find.byType(ToolbarItemWidget);
  final itemWidgets = tester
      .widgetList<ToolbarItemWidget>(finder)
      .where((element) => element.item.id == id);
  expect(itemWidgets.length, 1);
  return itemWidgets.first;
}
