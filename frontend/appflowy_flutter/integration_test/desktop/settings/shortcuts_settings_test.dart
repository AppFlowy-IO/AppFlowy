import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_shortcuts_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';
import '../board/board_hide_groups_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('shortcuts test', () {
    testWidgets('can change and overwrite shortcut', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.shortcuts);
      await tester.pumpAndSettle();

      final backspaceCmd =
          LocaleKeys.settings_shortcutsPage_keybindings_backspace.tr();

      // Input "Delete" into the search field
      await tester.enterText(find.byType(TextField), backspaceCmd);
      await tester.pumpAndSettle();

      await tester.hoverOnWidget(
        find.descendant(
          of: find.byType(ShortcutSettingTile),
          matching: find.text(backspaceCmd),
        ),
        onHover: () async {
          await tester.tap(find.byFlowySvg(FlowySvgs.edit_s));
          await tester.pumpAndSettle();

          await FlowyTestKeyboard.simulateKeyDownEvent(
            [
              LogicalKeyboardKey.delete,
              LogicalKeyboardKey.enter,
            ],
            tester: tester,
          );
          await tester.pumpAndSettle();
        },
      );

      // We expect to see conflict dialog
      expect(
        find.text(
          LocaleKeys.settings_shortcutsPage_conflictDialog_confirmLabel.tr(),
        ),
        findsOneWidget,
      );

      // Press on confirm label
      await tester.tap(
        find.text(
          LocaleKeys.settings_shortcutsPage_conflictDialog_confirmLabel.tr(),
        ),
      );
      await tester.pumpAndSettle();

      // We expect the first ShortcutSettingTile to have one
      // [KeyBadge] with `delete` label
      final first = tester.widget(find.byType(ShortcutSettingTile).first)
          as ShortcutSettingTile;
      expect(
        first.command.command,
        'delete',
      );

      // And the second one which is `Delete left character` to have none
      // as it will have been overwritten
      final second = tester.widget(find.byType(ShortcutSettingTile).at(1))
          as ShortcutSettingTile;
      expect(
        second.command.command,
        '',
      );
    });

    testWidgets('can reset an individual shortcut', (tester) async {
      // In order to reset a shortcut, we must first override it.

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.shortcuts);
      await tester.pumpAndSettle();

      final pageUpCmdText =
          LocaleKeys.settings_shortcutsPage_keybindings_pageUp.tr();
      final defaultPageUpCmd = pageUpCommand.command;

      // Input "Page Up text" into the search field
      // This test works because we only have one input field on the shortcuts page.
      await tester.enterText(find.byType(TextField), pageUpCmdText);
      await tester.pumpAndSettle();

      await tester.hoverOnWidget(
        find.descendant(
          of: find.byType(ShortcutSettingTile),
          matching: find.text(pageUpCmdText),
        ),
        onHover: () async {
          // changing the shortcut
          await tester.tap(find.byFlowySvg(FlowySvgs.edit_s));
          await tester.pumpAndSettle();

          await FlowyTestKeyboard.simulateKeyDownEvent(
            [
              LogicalKeyboardKey.backquote,
              LogicalKeyboardKey.enter,
            ],
            tester: tester,
          );
          await tester.pumpAndSettle();
        },
      );

      // We expect the first ShortcutSettingTile to have one
      // [KeyBadge] with `backquote` label
      // which will confirm that we have changed the command
      final theOnlyTile = tester.widget(find.byType(ShortcutSettingTile).first)
          as ShortcutSettingTile;
      expect(
        theOnlyTile.command.command,
        'backquote',
      );

      // hover on the ShortcutSettingTile and click the restore button
      await tester.hoverOnWidget(
        find.descendant(
          of: find.byType(ShortcutSettingTile),
          matching: find.text(pageUpCmdText),
        ),
        onHover: () async {
          await tester.tap(
            find.descendant(
              of: find.byType(ShortcutSettingTile).first,
              matching: find.byFlowySvg(FlowySvgs.restore_s),
            ),
          );
          await tester.pumpAndSettle();
        },
      );

      // We expect the first ShortcutSettingTile to have one
      // [KeyBadge] with `page up` label
      expect(
        theOnlyTile.command.command,
        defaultPageUpCmd,
      );
    });
  });
}
