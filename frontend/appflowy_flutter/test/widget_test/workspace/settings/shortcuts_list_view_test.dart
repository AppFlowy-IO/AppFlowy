import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  KeyEventResult dummyHandler(EditorState e, RawKeyEvent? r) =>
      KeyEventResult.handled;

  final dummyShortcuts = <ShortcutEvent>[
    ShortcutEvent(key: 'Copy', command: 'ctrl+c', handler: dummyHandler),
    ShortcutEvent(key: 'Paste', command: 'ctrl+v', handler: dummyHandler),
    ShortcutEvent(key: 'Undo', command: 'ctrl+z', handler: dummyHandler),
    ShortcutEvent(key: 'Redo', command: 'ctrl+y', handler: dummyHandler),
  ];

  group("ShortcutsListView", () {
    group("should be displayed correctly", () {
      testWidgets("with empty shortcut list", (widgetTester) async {
        await widgetTester.pumpWidget(
          const MaterialApp(
            home: ShortcutsListView(shortcuts: []),
          ),
        );

        expect(find.byType(FlowyText), findsNWidgets(2));
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(ShortcutsListTile), findsNothing);
      });

      testWidgets("with 1 item in shortcut list", (widgetTester) async {
        await widgetTester.pumpWidget(
          MaterialApp(
            home: ShortcutsListView(shortcuts: [dummyShortcuts[0]]),
          ),
        );

        expect(find.byType(FlowyText), findsAtLeastNWidgets(2));
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(ShortcutsListTile), findsOneWidget);
        expect(find.text(dummyShortcuts[0].key), findsOneWidget);
        expect(find.text(dummyShortcuts[0].command!), findsOneWidget);
      });

      testWidgets("with populated shortcut list", (widgetTester) async {
        await widgetTester.pumpWidget(
          MaterialApp(
            home: ShortcutsListView(shortcuts: dummyShortcuts),
          ),
        );

        expect(find.byType(FlowyText), findsAtLeastNWidgets(2));
        expect(find.byType(ListView), findsOneWidget);
        expect(
          find.byType(ShortcutsListTile),
          findsNWidgets(dummyShortcuts.length),
        );
        expect(find.text(dummyShortcuts[2].key), findsOneWidget);
        expect(find.text(dummyShortcuts[3].key), findsOneWidget);
      });
    });
  });
}
