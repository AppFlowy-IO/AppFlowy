import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  KeyEventResult dummyHandler(EditorState e) => KeyEventResult.handled;

  final dummyShortcuts = [
    CommandShortcutEvent(
      key: 'Copy',
      getDescription: () => 'Copy',
      command: 'ctrl+c',
      handler: dummyHandler,
    ),
    CommandShortcutEvent(
      key: 'Paste',
      getDescription: () => 'Paste',
      command: 'ctrl+v',
      handler: dummyHandler,
    ),
    CommandShortcutEvent(
      key: 'Undo',
      getDescription: () => 'Undo',
      command: 'ctrl+z',
      handler: dummyHandler,
    ),
    CommandShortcutEvent(
      key: 'Redo',
      getDescription: () => 'Redo',
      command: 'ctrl+y',
      handler: dummyHandler,
    ),
  ];

  group("ShortcutsListView", () {
    group("should be displayed correctly", () {
      testWidgets("with empty shortcut list", (widgetTester) async {
        await widgetTester.pumpWidget(
          const MaterialApp(
            home: ShortcutsListView(shortcuts: []),
          ),
        );

        expect(find.byType(FlowyText), findsNWidgets(3));
        //we expect three text widgets which are keybinding, command, and reset
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(ShortcutsListTile), findsNothing);
      });

      testWidgets("with 1 item in shortcut list", (widgetTester) async {
        await widgetTester.pumpWidget(
          MaterialApp(
            home: ShortcutsListView(shortcuts: [dummyShortcuts[0]]),
          ),
        );

        await widgetTester.pumpAndSettle();

        expect(find.byType(FlowyText), findsAtLeastNWidgets(3));
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(ShortcutsListTile), findsOneWidget);
      });

      testWidgets("with populated shortcut list", (widgetTester) async {
        await widgetTester.pumpWidget(
          MaterialApp(
            home: ShortcutsListView(shortcuts: dummyShortcuts),
          ),
        );

        expect(find.byType(FlowyText), findsAtLeastNWidgets(3));
        expect(find.byType(ListView), findsOneWidget);
        expect(
          find.byType(ShortcutsListTile),
          findsNWidgets(dummyShortcuts.length),
        );
      });
    });
  });
}
