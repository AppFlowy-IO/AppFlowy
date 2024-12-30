import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/publish_tab.dart';
import 'package:appflowy/plugins/shared/share/share_menu.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Publish:', () {
    testWidgets('publish document', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';

      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      // open the publish menu
      await tester.openPublishMenu();

      // publish the document
      final publishButton = find.byType(PublishButton);
      final unpublishButton = find.byType(UnPublishButton);
      await tester.tapButton(publishButton);

      // expect to see unpublish, visit site and manage all sites button
      expect(unpublishButton, findsOneWidget);
      expect(find.text(LocaleKeys.shareAction_visitSite.tr()), findsOneWidget);

      // unpublish the document
      await tester.tapButton(unpublishButton);

      // expect to see publish button
      expect(publishButton, findsOneWidget);
    });

    testWidgets('rename path name', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';

      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      // open the publish menu
      await tester.openPublishMenu();

      // publish the document
      final publishButton = find.byType(PublishButton);
      await tester.tapButton(publishButton);

      // rename the path name
      final inputField = find.descendant(
        of: find.byType(ShareMenu),
        matching: find.byType(TextField),
      );

      // rename with invalid name
      await tester.tap(inputField);
      await tester.enterText(inputField, '&&&&????');
      await tester.tapButton(find.text(LocaleKeys.button_save.tr()));
      await tester.pumpAndSettle();

      // expect to see the toast with error message
      final errorToast1 = find.text(
        LocaleKeys.settings_sites_error_publishNameContainsInvalidCharacters
            .tr(),
      );
      await tester.pumpUntilFound(errorToast1);
      await tester.pumpUntilNotFound(errorToast1);

      // rename with long name
      await tester.tap(inputField);
      await tester.enterText(inputField, 'long-path-name' * 200);
      await tester.tapButton(find.text(LocaleKeys.button_save.tr()));
      await tester.pumpAndSettle();

      // expect to see the toast with error message
      final errorToast2 = find.text(
        LocaleKeys.settings_sites_error_publishNameTooLong.tr(),
      );
      await tester.pumpUntilFound(errorToast2);
      await tester.pumpUntilNotFound(errorToast2);

      // rename with empty name
      await tester.tap(inputField);
      await tester.enterText(inputField, '');
      await tester.tapButton(find.text(LocaleKeys.button_save.tr()));
      await tester.pumpAndSettle();

      // expect to see the toast with error message
      final errorToast3 = find.text(
        LocaleKeys.settings_sites_error_publishNameCannotBeEmpty.tr(),
      );
      await tester.pumpUntilFound(errorToast3);
      await tester.pumpUntilNotFound(errorToast3);

      // input the new path name
      await tester.tap(inputField);
      await tester.enterText(inputField, 'new-path-name');
      // click save button
      await tester.tapButton(find.text(LocaleKeys.button_save.tr()));
      await tester.pumpAndSettle();

      // expect to see the toast with success message
      final successToast = find.text(
        LocaleKeys.settings_sites_success_updatePathNameSuccess.tr(),
      );
      await tester.pumpUntilFound(successToast);
      await tester.pumpUntilNotFound(successToast);

      // click the copy link button
      await tester.tapButton(
        find.byWidgetPredicate(
          (widget) =>
              widget is FlowySvg &&
              widget.svg.path == FlowySvgs.m_toolbar_link_m.path,
        ),
      );
      await tester.pumpAndSettle();
      // check the clipboard has the link
      final content = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        content?.text?.contains('new-path-name'),
        isTrue,
      );
    });

    testWidgets('re-publish the document', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';

      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      // open the publish menu
      await tester.openPublishMenu();

      // publish the document
      final publishButton = find.byType(PublishButton);
      await tester.tapButton(publishButton);

      // rename the path name
      final inputField = find.descendant(
        of: find.byType(ShareMenu),
        matching: find.byType(TextField),
      );

      // input the new path name
      const newName = 'new-path-name';
      await tester.enterText(inputField, newName);
      // click save button
      await tester.tapButton(find.text(LocaleKeys.button_save.tr()));
      await tester.pumpAndSettle();

      // expect to see the toast with success message
      final successToast = find.text(
        LocaleKeys.settings_sites_success_updatePathNameSuccess.tr(),
      );
      await tester.pumpUntilNotFound(successToast);

      // unpublish the document
      final unpublishButton = find.byType(UnPublishButton);
      await tester.tapButton(unpublishButton);

      final unpublishSuccessToast = find.text(
        LocaleKeys.publish_unpublishSuccessfully.tr(),
      );
      await tester.pumpUntilNotFound(unpublishSuccessToast);

      // re-publish the document
      await tester.tapButton(publishButton);

      // expect to see the toast with success message
      final rePublishSuccessToast = find.text(
        LocaleKeys.publish_publishSuccessfully.tr(),
      );
      await tester.pumpUntilNotFound(rePublishSuccessToast);

      // check the clipboard has the link
      final content = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        content?.text?.contains(newName),
        isTrue,
      );
    });
  });
}
