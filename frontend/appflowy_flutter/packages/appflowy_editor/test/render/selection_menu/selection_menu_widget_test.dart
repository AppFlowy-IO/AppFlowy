import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('selection_menu_widget.dart', () {
    // const i = defaultSelectionMenuItems.length;
    //
    // Because the `defaultSelectionMenuItems` uses localization,
    // and the MaterialApp has not been initialized at the time of getting the value,
    // it will crash.
    //
    // Use const value temporarily instead.
    const i = 7;
    testWidgets('Selects number.$i item in selection menu with keyboard',
        (tester) async {
      final editor = await _prepare(tester);
      for (var j = 0; j < i; j++) {
        await editor.pressLogicKey(key: LogicalKeyboardKey.arrowDown);
      }

      await editor.pressLogicKey(key: LogicalKeyboardKey.enter);
      expect(
        find.byType(SelectionMenuWidget, skipOffstage: false),
        findsNothing,
      );
      if (defaultSelectionMenuItems[i].name != 'Image') {
        await _testDefaultSelectionMenuItems(i, editor);
      }
    });

    testWidgets('Selects number.$i item in selection menu with clicking',
        (tester) async {
      final editor = await _prepare(tester);
      await tester.tap(find.byType(SelectionMenuItemWidget).at(i));
      await tester.pumpAndSettle();
      expect(
        find.byType(SelectionMenuWidget, skipOffstage: false),
        findsNothing,
      );
      if (defaultSelectionMenuItems[i].name != 'Image') {
        await _testDefaultSelectionMenuItems(i, editor);
      }
    });

    testWidgets('Search item in selection menu util no results',
        (tester) async {
      final editor = await _prepare(tester);
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyT);
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(key: LogicalKeyboardKey.backspace);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(5),
      );
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyX);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(1),
      );
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyT);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(1),
      );
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyT);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('Search item in selection menu and presses esc',
        (tester) async {
      final editor = await _prepare(tester);
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyT);
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(key: LogicalKeyboardKey.escape);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('Search item in selection menu and presses backspace',
        (tester) async {
      final editor = await _prepare(tester);
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyT);
      await editor.pressLogicKey(key: LogicalKeyboardKey.keyE);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNWidgets(3),
      );
      await editor.pressLogicKey(key: LogicalKeyboardKey.backspace);
      await editor.pressLogicKey(key: LogicalKeyboardKey.backspace);
      await editor.pressLogicKey(key: LogicalKeyboardKey.backspace);
      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });

    group('tab and arrow keys move selection in desired direction', () {
      testWidgets('left and right keys move selection in desired direction',
          (tester) async {
        final editor = await _prepare(tester);

        var initialSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(initialSelection.item), 0);

        await editor.pressLogicKey(key: LogicalKeyboardKey.arrowRight);

        var newSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(newSelection.item), 5);

        await editor.pressLogicKey(key: LogicalKeyboardKey.arrowLeft);

        var finalSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(initialSelection.item), 0);
      });

      testWidgets('up and down keys move selection in desired direction',
          (tester) async {
        final editor = await _prepare(tester);

        var initialSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(initialSelection.item), 0);

        await editor.pressLogicKey(key: LogicalKeyboardKey.arrowDown);

        var newSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(newSelection.item), 1);

        await editor.pressLogicKey(key: LogicalKeyboardKey.arrowUp);

        var finalSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(finalSelection.item), 0);
      });

      testWidgets('arrow keys and tab move same selection', (tester) async {
        final editor = await _prepare(tester);

        var initialSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(initialSelection.item), 0);

        await editor.pressLogicKey(key: LogicalKeyboardKey.arrowDown);

        var newSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(newSelection.item), 1);

        await editor.pressLogicKey(key: LogicalKeyboardKey.tab);

        var finalSelection = getSelectedMenuItem(tester);
        expect(defaultSelectionMenuItems.indexOf(finalSelection.item), 6);
      });

      testWidgets(
          'tab moves selection to next row Item on reaching end of current row',
          (tester) async {
        final editor = await _prepare(tester);

        final initialSelection = getSelectedMenuItem(tester);

        expect(defaultSelectionMenuItems.indexOf(initialSelection.item), 0);

        await editor.pressLogicKey(key: LogicalKeyboardKey.tab);
        await editor.pressLogicKey(key: LogicalKeyboardKey.tab);

        final finalSelection = getSelectedMenuItem(tester);

        expect(defaultSelectionMenuItems.indexOf(finalSelection.item), 1);
      });
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
  await editor.pressLogicKey(key: LogicalKeyboardKey.slash);

  await tester.pumpAndSettle(const Duration(milliseconds: 1000));

  expect(
    find.byType(SelectionMenuWidget, skipOffstage: false),
    findsOneWidget,
  );

  for (final item in defaultSelectionMenuItems) {
    expect(find.text(item.name), findsOneWidget);
  }

  return Future.value(editor);
}

Future<void> _testDefaultSelectionMenuItems(
    int index, EditorWidgetTester editor) async {
  expect(editor.documentLength, 4);
  expect(editor.documentSelection, Selection.single(path: [2], startOffset: 0));
  expect((editor.nodeAtPath([0]) as TextNode).toPlainText(),
      'Welcome to Appflowy 😁');
  expect((editor.nodeAtPath([1]) as TextNode).toPlainText(),
      'Welcome to Appflowy 😁');
  final node = editor.nodeAtPath([2]);
  final item = defaultSelectionMenuItems[index];
  if (item.name == 'Text') {
    expect(node?.subtype == null, true);
    expect(node?.toString(), null);
  } else if (item.name == 'Heading 1') {
    expect(node?.subtype, BuiltInAttributeKey.heading);
    expect(node?.attributes.heading, BuiltInAttributeKey.h1);
    expect(node?.toString(), null);
  } else if (item.name == 'Heading 2') {
    expect(node?.subtype, BuiltInAttributeKey.heading);
    expect(node?.attributes.heading, BuiltInAttributeKey.h2);
    expect(node?.toString(), null);
  } else if (item.name == 'Heading 3') {
    expect(node?.subtype, BuiltInAttributeKey.heading);
    expect(node?.attributes.heading, BuiltInAttributeKey.h3);
    expect(node?.toString(), null);
  } else if (item.name == 'Bulleted list') {
    expect(node?.subtype, BuiltInAttributeKey.bulletedList);
  } else if (item.name == 'Checkbox') {
    expect(node?.subtype, BuiltInAttributeKey.checkbox);
    expect(node?.attributes.check, false);
  }
}

SelectionMenuItemWidget getSelectedMenuItem(WidgetTester tester) {
  return tester
      .state(find.byWidgetPredicate(
        (widget) => widget is SelectionMenuItemWidget && widget.isSelected,
      ))
      .widget as SelectionMenuItemWidget;
}
