import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/draggable_option_button.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document option actions:', () {
    testWidgets('drag block to the top', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open getting started page
      await tester.openPage(Constants.gettingStartedPageName);

      // before move
      final beforeMoveBlock = tester.editor.getNodeAtPath([1]);

      // move the desktop guide to the top, above the getting started
      await tester.editor.dragBlock(
        [1],
        const Offset(20, -80),
      );

      // wait for the move animation to complete
      await tester.pumpAndSettle(Durations.short1);

      // check if the block is moved to the top
      final afterMoveBlock = tester.editor.getNodeAtPath([0]);
      expect(afterMoveBlock.delta, beforeMoveBlock.delta);
    });

    testWidgets('drag block to other block\'s child', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open getting started page
      await tester.openPage(Constants.gettingStartedPageName);

      // before move
      final beforeMoveBlock = tester.editor.getNodeAtPath([10]);

      // move the checkbox to the child of the block at path [9]
      await tester.editor.dragBlock(
        [10],
        const Offset(80, -30),
      );

      // wait for the move animation to complete
      await tester.pumpAndSettle(Durations.short1);

      // check if the block is moved to the child of the block at path [9]
      final afterMoveBlock = tester.editor.getNodeAtPath([9, 0]);
      expect(afterMoveBlock.delta, beforeMoveBlock.delta);
    });

    // Copy link to block feature is disable temporarily, enable this test when the feature is ready.
    // testWidgets('copy block link', (tester) async {
    //   await tester.initializeAppFlowy(
    //     cloudType: AuthenticatorType.appflowyCloudSelfHost,
    //   );
    //   await tester.tapGoogleLoginInButton();
    //   await tester.expectToSeeHomePageWithGetStartedPage();

    //   // open getting started page
    //   await tester.openPage(Constants.gettingStartedPageName);

    //   // hover and click on the option menu button beside the block component.
    //   await tester.editor.hoverAndClickOptionMenuButton([0]);

    //   // click the copy link to block option
    //   await tester.tap(
    //     find.findTextInFlowyText(
    //       LocaleKeys.document_plugins_optionAction_copyLinkToBlock.tr(),
    //     ),
    //   );
    //   await tester.pumpAndSettle(Durations.short1);

    //   // check the clipboard
    //   final content = await Clipboard.getData(Clipboard.kTextPlain);
    //   expect(
    //     content?.text,
    //     matches(
    //       r'^https:\/\/appflowy\.com\/app\/[a-f0-9-]{36}\/[a-f0-9-]{36}\?blockId=[A-Za-z0-9_-]+$',
    //     ),
    //   );
    // });

    testWidgets('hover on the block and delete it', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open getting started page
      await tester.openPage(Constants.gettingStartedPageName);

      // before delete
      final path = [1];
      final beforeDeletedBlock = tester.editor.getNodeAtPath(path);

      // hover on the block and delete it
      final optionButton = find.byWidgetPredicate(
        (widget) =>
            widget is DraggableOptionButton &&
            widget.blockComponentContext.node.path.equals(path),
      );

      await tester.hoverOnWidget(
        optionButton,
        onHover: () async {
          // click the delete button
          await tester.tapButton(optionButton);
        },
      );
      await tester.pumpAndSettle(Durations.short1);

      // click the delete button
      final deleteButton =
          find.findTextInFlowyText(LocaleKeys.button_delete.tr());
      await tester.tapButton(deleteButton);

      // wait for the deletion
      await tester.pumpAndSettle(Durations.short1);

      // check if the block is deleted
      final afterDeletedBlock = tester.editor.getNodeAtPath([1]);
      expect(afterDeletedBlock.id, isNot(equals(beforeDeletedBlock.id)));
    });
  });
}
