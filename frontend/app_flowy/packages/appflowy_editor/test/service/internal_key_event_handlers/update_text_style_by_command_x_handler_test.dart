import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/link_menu/link_menu.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('update_text_style_by_command_x_handler.dart', () {
    testWidgets('Presses Command + B to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.bold,
        true,
        LogicalKeyboardKey.keyB,
      );
    });
    testWidgets('Presses Command + I to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.italic,
        true,
        LogicalKeyboardKey.keyI,
      );
    });
    testWidgets('Presses Command + U to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.underline,
        true,
        LogicalKeyboardKey.keyU,
      );
    });
    testWidgets('Presses Command + Shift + S to update text style',
        (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.strikethrough,
        true,
        LogicalKeyboardKey.keyS,
      );
    });

    testWidgets('Presses Command + Shift + H to update text style',
        (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.backgroundColor,
        defaultHighlightColor,
        LogicalKeyboardKey.keyH,
      );
    });

    testWidgets('Presses Command + K to trigger link menu', (tester) async {
      await _testLinkMenuInSingleTextSelection(tester);
    });
  });
}

Future<void> _testUpdateTextStyleByCommandX(
  WidgetTester tester,
  String matchStyle,
  dynamic matchValue,
  LogicalKeyboardKey key,
) async {
  final isShiftPressed =
      key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.keyH;
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();

  var selection =
      Selection.single(path: [1], startOffset: 2, endOffset: text.length - 2);
  await editor.updateSelection(selection);
  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isControlPressed: true,
    );
  } else {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isMetaPressed: true,
    );
  }
  var textNode = editor.nodeAtPath([1]) as TextNode;
  expect(
      textNode.allSatisfyInSelection(
        selection,
        matchStyle,
        (value) {
          return value == matchValue;
        },
      ),
      true);

  selection =
      Selection.single(path: [1], startOffset: 0, endOffset: text.length);
  await editor.updateSelection(selection);
  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isControlPressed: true,
    );
  } else {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isMetaPressed: true,
    );
  }
  textNode = editor.nodeAtPath([1]) as TextNode;
  expect(
      textNode.allSatisfyInSelection(
        selection,
        matchStyle,
        (value) {
          return value == matchValue;
        },
      ),
      true);

  await editor.updateSelection(selection);
  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isControlPressed: true,
    );
  } else {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isMetaPressed: true,
    );
  }
  textNode = editor.nodeAtPath([1]) as TextNode;
  expect(textNode.allNotSatisfyInSelection(matchStyle, matchValue, selection),
      true);

  selection = Selection(
    start: Position(path: [0], offset: 0),
    end: Position(path: [2], offset: text.length),
  );
  await editor.updateSelection(selection);
  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isControlPressed: true,
    );
  } else {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isMetaPressed: true,
    );
  }
  var nodes = editor.editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  expect(nodes.length, 3);
  for (final node in nodes) {
    expect(
      node.allSatisfyInSelection(
        Selection.single(
          path: node.path,
          startOffset: 0,
          endOffset: text.length,
        ),
        matchStyle,
        (value) {
          return value == matchValue;
        },
      ),
      true,
    );
  }

  await editor.updateSelection(selection);

  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isControlPressed: true,
    );
  } else {
    await editor.pressLogicKey(
      key,
      isShiftPressed: isShiftPressed,
      isMetaPressed: true,
    );
  }
  nodes = editor.editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  expect(nodes.length, 3);
  for (final node in nodes) {
    expect(
      node.allNotSatisfyInSelection(
        matchStyle,
        matchValue,
        Selection.single(
            path: node.path, startOffset: 0, endOffset: text.length),
      ),
      true,
    );
  }
}

Future<void> _testLinkMenuInSingleTextSelection(WidgetTester tester) async {
  const link = 'appflowy.io';
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();

  final selection =
      Selection.single(path: [1], startOffset: 0, endOffset: text.length);
  await editor.updateSelection(selection);

  // show toolbar
  expect(find.byType(ToolbarWidget), findsOneWidget);

  // trigger the link menu
  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(LogicalKeyboardKey.keyK, isControlPressed: true);
  } else {
    await editor.pressLogicKey(LogicalKeyboardKey.keyK, isMetaPressed: true);
  }
  expect(find.byType(LinkMenu), findsOneWidget);

  await tester.enterText(find.byType(TextField), link);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  expect(find.byType(LinkMenu), findsNothing);

  final node = editor.nodeAtPath([1]) as TextNode;
  expect(
      node.allSatisfyInSelection(
        selection,
        StyleKey.href,
        (value) => value == link,
      ),
      true);

  await editor.updateSelection(selection);
  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(LogicalKeyboardKey.keyK, isControlPressed: true);
  } else {
    await editor.pressLogicKey(LogicalKeyboardKey.keyK, isMetaPressed: true);
  }
  expect(find.byType(LinkMenu), findsOneWidget);
  expect(
      find.text(link, findRichText: true, skipOffstage: false), findsOneWidget);

  // Copy link
  final copyLink = find.text('Copy link');
  expect(copyLink, findsOneWidget);
  await tester.tap(copyLink);
  await tester.pumpAndSettle();
  expect(find.byType(LinkMenu), findsNothing);

  // Remove link
  if (Platform.isWindows || Platform.isLinux) {
    await editor.pressLogicKey(LogicalKeyboardKey.keyK, isControlPressed: true);
  } else {
    await editor.pressLogicKey(LogicalKeyboardKey.keyK, isMetaPressed: true);
  }
  final removeLink = find.text('Remove link');
  expect(removeLink, findsOneWidget);
  await tester.tap(removeLink);
  await tester.pumpAndSettle();
  expect(find.byType(LinkMenu), findsNothing);

  expect(
      node.allSatisfyInSelection(
        selection,
        StyleKey.href,
        (value) => value == link,
      ),
      false);
}
