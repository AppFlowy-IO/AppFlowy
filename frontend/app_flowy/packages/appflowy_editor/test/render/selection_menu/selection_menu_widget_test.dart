import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_item_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('selection_menu_widget.dart', () {
    for (var i = 0; i < defaultSelectionMenuItems.length; i += 1) {
      testWidgets('Selects number.$i item in selection menu with enter',
          (tester) async {
        final editor = await _prepare(tester);
        for (var j = 0; j < i; j++) {
          await editor.pressLogicKey(LogicalKeyboardKey.arrowDown);
        }

        await editor.pressLogicKey(LogicalKeyboardKey.enter);
        expect(
          find.byType(SelectionMenuWidget, skipOffstage: false),
          findsNothing,
        );
        if (defaultSelectionMenuItems[i].name() != 'Image') {
          await _testDefaultSelectionMenuItems(i, editor);
        }
      });

      testWidgets('Selects number.$i item in selection menu with click',
          (tester) async {
        final editor = await _prepare(tester);

        await tester.tap(find.byType(SelectionMenuItemWidget).at(i));
        await tester.pumpAndSettle();

        expect(
          find.byType(SelectionMenuWidget, skipOffstage: false),
          findsNothing,
        );
        if (defaultSelectionMenuItems[i].name() != 'Image') {
          await _testDefaultSelectionMenuItems(i, editor);
        }
      });
    }

    testWidgets('Search item in selection menu util no results',
        (tester) async {
      final editor = await _prepare(tester);
      await editor.pressLogicKey(LogicalKeyboardKey.keyT);
      await editor.pressLogicKey(LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.backspace);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(5),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.keyX);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(1),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.keyT);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(1),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.keyT);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('Search item in selection menu and presses esc',
        (tester) async {
      final editor = await _prepare(tester);
      await editor.pressLogicKey(LogicalKeyboardKey.keyT);
      await editor.pressLogicKey(LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.escape);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('Search item in selection menu and presses backspace',
        (tester) async {
      final editor = await _prepare(tester);
      await editor.pressLogicKey(LogicalKeyboardKey.keyT);
      await editor.pressLogicKey(LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.backspace);
      await editor.pressLogicKey(LogicalKeyboardKey.backspace);
      await editor.pressLogicKey(LogicalKeyboardKey.backspace);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });
  });
}

Future<EditorWidgetTester> _prepare(WidgetTester tester) async {
  const text = 'Welcome to Appflowy 😁';
  const lines = 3;
  final editor = tester.editor;
  for (var i = 0; i < lines; i++) {
    editor.insertTextNode(text);
  }
  await editor.startTesting();
  await editor.updateSelection(Selection.single(path: [1], startOffset: 0));
  await editor.pressLogicKey(LogicalKeyboardKey.slash);

  await tester.pumpAndSettle(const Duration(milliseconds: 1000));

  expect(
    find.byType(SelectionMenuWidget, skipOffstage: false),
    findsOneWidget,
  );

  for (final item in defaultSelectionMenuItems) {
    expect(find.text(item.name()), findsOneWidget);
  }

  return Future.value(editor);
}

Future<void> _testDefaultSelectionMenuItems(
    int index, EditorWidgetTester editor) async {
  expect(editor.documentLength, 4);
  expect(editor.documentSelection, Selection.single(path: [2], startOffset: 0));
  expect((editor.nodeAtPath([1]) as TextNode).toPlainText(),
      'Welcome to Appflowy 😁');
  final node = editor.nodeAtPath([2]);
  final item = defaultSelectionMenuItems[index];
  final itemName = item.name();
  if (itemName == 'Text') {
    expect(node?.subtype == null, true);
  } else if (itemName == 'Heading 1') {
    expect(node?.subtype, BuiltInAttributeKey.heading);
    expect(node?.attributes.heading, BuiltInAttributeKey.h1);
  } else if (itemName == 'Heading 2') {
    expect(node?.subtype, BuiltInAttributeKey.heading);
    expect(node?.attributes.heading, BuiltInAttributeKey.h2);
  } else if (itemName == 'Heading 3') {
    expect(node?.subtype, BuiltInAttributeKey.heading);
    expect(node?.attributes.heading, BuiltInAttributeKey.h3);
  } else if (itemName == 'Bulleted list') {
    expect(node?.subtype, BuiltInAttributeKey.bulletedList);
  } else if (itemName == 'Checkbox') {
    expect(node?.subtype, BuiltInAttributeKey.checkbox);
    expect(node?.attributes.check, false);
  } else if (itemName == 'Quote') {
    expect(node?.subtype, BuiltInAttributeKey.quote);
  }
}
