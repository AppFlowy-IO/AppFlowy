import 'dart:io';

import 'package:appflowy_editor/src/service/shortcut_event/built_in_shortcut_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('shortcut_event.dart', () {
    test('redefine shortcut event command', () {
      final shortcutEvent = ShortcutEvent(
        key: 'Sample',
        command: 'cmd+shift+alt+ctrl+a',
        handler: (editorState, event) {
          return KeyEventResult.handled;
        },
      );
      shortcutEvent.updateCommand(command: 'cmd+shift+alt+ctrl+b');
      expect(shortcutEvent.keybindings.length, 1);
      expect(shortcutEvent.keybindings.first.isMetaPressed, true);
      expect(shortcutEvent.keybindings.first.isShiftPressed, true);
      expect(shortcutEvent.keybindings.first.isAltPressed, true);
      expect(shortcutEvent.keybindings.first.isControlPressed, true);
      expect(shortcutEvent.keybindings.first.keyLabel, 'b');
    });

    testWidgets('redefine move cursor begin command', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: text.length),
      );
      if (Platform.isWindows || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowLeft,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowLeft,
          isMetaPressed: true,
        );
      }
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0),
      );
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: text.length),
      );

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Move cursor begin') {
          event.updateCommand(
            windowsCommand: 'alt+arrow left',
            linuxCommand: 'alt+arrow left',
            macOSCommand: 'alt+arrow left',
          );
        }
      }
      if (Platform.isWindows || Platform.isMacOS) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowLeft,
          isAltPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowLeft,
          isMetaPressed: true,
        );
      }
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0),
      );
    });

    testWidgets('redefine move cursor end command', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: 0),
      );
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowRight,
          isControlPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowLeft,
          isMetaPressed: true,
        );
      }
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: text.length),
      );
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: 0),
      );

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Move cursor end') {
          event.updateCommand(
            windowsCommand: 'alt+arrow right',
            linuxCommand: 'alt+arrow right',
            macOSCommand: 'alt+arrow right',
          );
        }
      }
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowRight,
          isAltPressed: true,
        );
      } else {
        await editor.pressLogicKey(
          LogicalKeyboardKey.arrowRight,
          isMetaPressed: true,
        );
      }
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: text.length),
      );
    });

    testWidgets('Test Home Key to move to start of current text',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: text.length),
      );
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.home,
        );
      }

      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0),
      );
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: text.length),
      );

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Move cursor begin') {
          event.updateCommand(
            windowsCommand: 'home',
            linuxCommand: 'home',
            macOSCommand: 'home',
          );
        }
      }
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.home,
        );
      }
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0),
      );
    });

    testWidgets('Test End Key to move to end of current text', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: text.length),
      );
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.end,
        );
      }

      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: text.length),
      );
      await editor.updateSelection(
        Selection.single(path: [1], startOffset: 0),
      );

      for (final event in builtInShortcutEvents) {
        if (event.key == 'Move cursor end') {
          event.updateCommand(
            windowsCommand: 'end',
            linuxCommand: 'end',
            macOSCommand: 'end',
          );
        }
      }
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.end,
        );
      }
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: text.length),
      );
    });
  });
}
