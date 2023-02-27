import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/service/shortcut_event/built_in_shortcut_events.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('checkbox_event_handler_test.dart', () {
    testWidgets('toggle checkbox with shortcut ctrl+enter', (tester) async {
      const text = 'Checkbox1';
      final editor = tester.editor
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: false,
          },
          delta: Delta(
            operations: [TextInsert(text)],
          ),
        );
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: text.length),
      );

      final checkboxNode = editor.nodeAtPath([0]) as TextNode;
      expect(checkboxNode.subtype, BuiltInAttributeKey.checkbox);
      expect(checkboxNode.attributes[BuiltInAttributeKey.checkbox], false);

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Toggle Checkbox') {
          event.updateCommand(
            windowsCommand: 'ctrl+enter',
            linuxCommand: 'ctrl+enter',
            macOSCommand: 'meta+enter',
          );
        }
      }

      if (Platform.isWindows || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isMetaPressed: true,
        );
      }

      expect(checkboxNode.attributes[BuiltInAttributeKey.checkbox], true);

      await editor.updateSelection(
        Selection.single(path: [0], startOffset: text.length),
      );

      if (Platform.isWindows || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isMetaPressed: true,
        );
      }

      expect(checkboxNode.attributes[BuiltInAttributeKey.checkbox], false);
    });

    testWidgets(
        'test if all checkboxes get unchecked after toggling them, if all of them were already checked',
        (tester) async {
      const text = 'Checkbox';
      final editor = tester.editor
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: true,
          },
          delta: Delta(
            operations: [TextInsert(text)],
          ),
        )
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: true,
          },
          delta: Delta(
            operations: [TextInsert(text)],
          ),
        )
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: true,
          },
          delta: Delta(
            operations: [TextInsert(text)],
          ),
        );

      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: text.length),
      );

      final nodes =
          editor.editorState.service.selectionService.currentSelectedNodes;
      final checkboxTextNodes = nodes
          .where(
            (element) =>
                element is TextNode &&
                element.subtype == BuiltInAttributeKey.checkbox,
          )
          .toList(growable: false);

      for (final node in checkboxTextNodes) {
        expect(node.attributes[BuiltInAttributeKey.checkbox], true);
      }

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Toggle Checkbox') {
          event.updateCommand(
            windowsCommand: 'ctrl+enter',
            linuxCommand: 'ctrl+enter',
            macOSCommand: 'meta+enter',
          );
        }
      }

      if (Platform.isWindows || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isMetaPressed: true,
        );
      }

      for (final node in checkboxTextNodes) {
        expect(node.attributes[BuiltInAttributeKey.checkbox], false);
      }
    });

    testWidgets(
        'test if all checkboxes get checked after toggling them, if any one of them were already checked',
        (tester) async {
      const text = 'Checkbox';
      final editor = tester.editor
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: false,
          },
          delta: Delta(
            operations: [TextInsert(text)],
          ),
        )
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: true,
          },
          delta: Delta(
            operations: [TextInsert(text)],
          ),
        )
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: false,
          },
          delta: Delta(
            operations: [TextInsert(text)],
          ),
        );

      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: text.length),
      );

      final nodes =
          editor.editorState.service.selectionService.currentSelectedNodes;
      final checkboxTextNodes = nodes
          .where(
            (element) =>
                element is TextNode &&
                element.subtype == BuiltInAttributeKey.checkbox,
          )
          .toList(growable: false);

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Toggle Checkbox') {
          event.updateCommand(
            windowsCommand: 'ctrl+enter',
            linuxCommand: 'ctrl+enter',
            macOSCommand: 'meta+enter',
          );
        }
      }

      if (Platform.isWindows || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
          isMetaPressed: true,
        );
      }

      for (final node in checkboxTextNodes) {
        expect(node.attributes[BuiltInAttributeKey.checkbox], true);
      }
    });
  });
}
