import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/draggable_option_button.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/constants.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document delete block: ', () {
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
