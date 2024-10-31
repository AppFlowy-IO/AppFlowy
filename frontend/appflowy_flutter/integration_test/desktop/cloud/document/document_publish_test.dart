// ignore_for_file: unused_import

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/plugins/shared/share/publish_tab.dart';
import 'package:appflowy/plugins/shared/share/share_menu.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/constants.dart';
import '../../../shared/mock/mock_file_picker.dart';
import '../../../shared/util.dart';
import '../../../shared/workspace.dart';

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
      expect(
        find.text(LocaleKeys.shareAction_manageAllSites.tr()),
        findsOneWidget,
      );

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

      await tester.tap(inputField);

      // input the new path name
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
  });
}
