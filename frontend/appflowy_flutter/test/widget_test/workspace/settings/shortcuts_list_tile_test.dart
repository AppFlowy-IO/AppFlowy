import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  KeyEventResult dummyHandler(EditorState e, RawKeyEvent? r) =>
      KeyEventResult.handled;

  final shortcut = ShortcutEvent(
    key: 'Copy',
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
              widgetTester.widget<FlowyText>(commandTextFinder).title;

          expect(commandTextFinder, findsOneWidget);
          expect(foundCommand, shortcut.key);

          final btnFinder = find.byType(FlowyTextButton);
          final foundBtnText =
              widgetTester.widget<FlowyTextButton>(btnFinder).text;

          expect(btnFinder, findsOneWidget);
          expect(foundBtnText, shortcut.command);
        });

        testWidgets(
          "without command",
          (widgetTester) async {
            KeyEventResult dummyHandler(EditorState e, RawKeyEvent? r) =>
                KeyEventResult.handled;

            final shortcut2 = ShortcutEvent(
              key: 'Selection Menu',
              character: '/',
              command: null,
              handler: dummyHandler,
            );

            final sKey = Key(shortcut2.key);

            await widgetTester.pumpWidget(
              MaterialApp(
                home: ShortcutsListTile(shortcutEvent: shortcut2),
              ),
            );

            final commandTextFinder = find.byKey(sKey);
            final foundCommand =
                widgetTester.widget<FlowyText>(commandTextFinder).title;

            expect(commandTextFinder, findsOneWidget);
            expect(foundCommand, shortcut2.key);

            expect(find.byType(FlowyTextButton), findsOneWidget);
          },
        );
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
          expect(find.byType(RawKeyboardListener), findsOneWidget);
          expect(find.text(shortcut.command!), findsNWidgets(2));
          //here we expect 2 texts bcz one is on the flowytextbtn and the other
          //is inside the textfield of rawkeyboardlistener.
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
          expect(find.byType(RawKeyboardListener), findsOneWidget);

          await widgetTester.sendKeyEvent(LogicalKeyboardKey.keyC);

          expect(find.text('c'), findsOneWidget);
        });
      },
    );
  });
}
