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
    testWidgets('toggle checkbox with shortcut ctrl+q', (tester) async {
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
      expect(checkboxNode.attributes.check, false);

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Toggle Checkbox') {
          event.updateCommand(
            windowsCommand: 'ctrl+q',
            linuxCommand: 'ctrl+q',
            macOSCommand: 'meta+q',
          );
        }
      }

      if (Platform.isWindows || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.keyQ,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.keyQ,
          isMetaPressed: true,
        );
      }

      expect(checkboxNode.attributes.check, true);

      if (Platform.isWindows || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.keyQ,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.keyQ,
          isMetaPressed: true,
        );
      }

      expect(checkboxNode.attributes.check, false);
    });
  });
}
