import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/workspaces/create_workspace_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('publish:', () {
    testWidgets('publish document', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      await tester.openPage(Constants.gettingStartedPageName);
      await tester.editor.openMoreActionMenuOnMobile();

      // click the publish button
      await tester.editor.clickMoreActionItemOnMobile(
        LocaleKeys.shareAction_publish.tr(),
      );

      // wait the notification dismiss
      final publishSuccessText = find.findTextInFlowyText(
        LocaleKeys.publish_publishSuccessfully.tr(),
      );
      expect(publishSuccessText, findsOneWidget);
      await tester.pumpUntilNotFound(publishSuccessText);

      // open the menu again, to check the publish status
      await tester.editor.openMoreActionMenuOnMobile();
      // expect to see the unpublish button and the visit site button
      expect(
        find.text(LocaleKeys.shareAction_unPublish.tr()),
        findsOneWidget,
      );
      expect(
        find.text(LocaleKeys.shareAction_visitSite.tr()),
        findsOneWidget,
      );

      // update the path name
      await tester.editor.clickMoreActionItemOnMobile(
        LocaleKeys.shareAction_updatePathName.tr(),
      );

      const pathName1 = '???????????????';
      const pathName2 = 'AppFlowy';

      final textField = find.descendant(
        of: find.byType(EditWorkspaceNameBottomSheet),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textField, pathName2);

      // click the confirm button
      final confirmButton = find.text(LocaleKeys.button_confirm.tr());
      await tester.tap(confirmButton);

      // expect to see the error message
      final errorMessage = find.findTextInFlowyText(
        LocaleKeys.settings_sites_error_updatePathNameFailed.tr(),
      );
      expect(errorMessage, findsOneWidget);

      // expect to see the update path name success toast
      final updatePathFailedText = find.findTextInFlowyText(
        LocaleKeys.settings_sites_error_publishNameContainsInvalidCharacters
            .tr(),
      );
      expect(updatePathFailedText, findsOneWidget);

      // input the valid path name
      await tester.enterText(textField, pathName2);
      // click the confirm button
      await tester.tap(confirmButton);

      // expect to see the update path name success toast
      final updatePathSuccessText = find.findTextInFlowyText(
        LocaleKeys.settings_sites_success_updatePathNameSuccess.tr(),
      );
      expect(updatePathSuccessText, findsOneWidget);
      await tester.pumpUntilNotFound(updatePathSuccessText);

      // unpublish the document
      await tester.editor.clickMoreActionItemOnMobile(
        LocaleKeys.shareAction_unPublish.tr(),
      );
      final unPublishSuccessText = find.findTextInFlowyText(
        LocaleKeys.publish_unpublishSuccessfully.tr(),
      );
      expect(unPublishSuccessText, findsOneWidget);
      await tester.pumpUntilNotFound(unPublishSuccessText);
    });
  });
}
