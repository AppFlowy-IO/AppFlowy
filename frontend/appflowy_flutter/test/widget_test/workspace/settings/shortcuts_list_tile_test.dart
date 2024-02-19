import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  KeyEventResult dummyHandler(EditorState e) => KeyEventResult.handled;

  final shortcut = CommandShortcutEvent(
    key: 'Copy',
    getDescription: () => 'Copy',
    command: 'ctrl+c',
    handler: dummyHandler,
  );

  group("ShortcutsListTile", () {
    group(
      "should be displayed correctly",
      () {
        testWidgets('with key and command', (widgetTester) async {
          final sKey = Key(shortcut.key);

          await widgetTester.pumpWidget(
            MaterialApp(
              home: ShortcutsListTile(shortcutEvent: shortcut),
            ),
          );

          final commandTextFinder = find.byKey(sKey);
          final foundCommand =
              widgetTester.widget<FlowyText>(commandTextFinder).text;

          expect(commandTextFinder, findsOneWidget);
          expect(foundCommand, shortcut.key);

          final btnFinder = find.byType(FlowyTextButton);
          final foundBtnText =
              widgetTester.widget<FlowyTextButton>(btnFinder).text;

          expect(btnFinder, findsOneWidget);
          expect(foundBtnText, shortcut.command);
        });
      },
    );

    group(
      "taps the button",
      () {
        testWidgets("opens AlertDialog correctly", (widgetTester) async {
          await widgetTester.pumpWidget(
            MaterialApp(
              home: ShortcutsListTile(shortcutEvent: shortcut),
            ),
          );

          final btnFinder = find.byType(FlowyTextButton);
          final foundBtnText =
              widgetTester.widget<FlowyTextButton>(btnFinder).text;

          expect(btnFinder, findsOneWidget);
          expect(foundBtnText, shortcut.command);

          await widgetTester.tap(btnFinder);
          await widgetTester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.byType(KeyboardListener), findsOneWidget);
        });

        testWidgets("updates the text with new key event",
            (widgetTester) async {
          await widgetTester.pumpWidget(
            MaterialApp(
              home: ShortcutsListTile(shortcutEvent: shortcut),
            ),
          );

          final btnFinder = find.byType(FlowyTextButton);

          await widgetTester.tap(btnFinder);
          await widgetTester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.byType(KeyboardListener), findsOneWidget);

          await widgetTester.sendKeyEvent(LogicalKeyboardKey.keyC);

          expect(find.text('c'), findsOneWidget);
        });
      },
    );
  });
}
