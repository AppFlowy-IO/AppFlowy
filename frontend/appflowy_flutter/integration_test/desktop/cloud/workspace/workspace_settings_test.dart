import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/plugins/shared/share/publish_tab.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_more_action.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_more_action.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_list_tile.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('workspace settings: ', () {
    testWidgets(
      'change document width',
      (tester) async {
        await tester.initializeAppFlowy(
          cloudType: AuthenticatorType.appflowyCloudSelfHost,
        );
        await tester.tapGoogleLoginInButton();
        await tester.expectToSeeHomePageWithGetStartedPage();

        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.workspace);

        final documentWidthSettings = find.findTextInFlowyText(
          LocaleKeys.settings_appearance_documentSettings_width.tr(),
        );

        final scrollable = find.ancestor(
          of: find.byType(SettingsWorkspaceView),
          matching: find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          ),
        );

        await tester.scrollUntilVisible(
          documentWidthSettings,
          0,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();

        // change the document width
        final slider = find.byType(Slider);
        final oldValue = tester.widget<Slider>(slider).value;
        await tester.drag(slider, const Offset(-100, 0));
        await tester.pumpAndSettle();

        // check the document width is changed
        expect(tester.widget<Slider>(slider).value, lessThan(oldValue));

        // click the reset button
        final resetButton = find.descendant(
          of: find.byType(DocumentPaddingSetting),
          matching: find.byType(SettingsResetButton),
        );
        await tester.tap(resetButton);
        await tester.pumpAndSettle();

        // check the document width is reset
        expect(
          tester.widget<Slider>(slider).value,
          EditorStyleCustomizer.maxDocumentWidth,
        );
      },
    );
  });

  group('sites settings:', () {
    testWidgets(
        'manage published page, set it as homepage, remove the homepage',
        (tester) async {
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
      await tester.tapButton(find.byType(PublishButton));

      // click empty area to close the publish menu
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      // check if the page is published in sites page
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.sites);
      // wait the backend return the sites data
      await tester.wait(1000);

      // check if the page is published in sites page
      final pageItem = find.byWidgetPredicate(
        (widget) =>
            widget is PublishedViewItem &&
            widget.publishInfoView.view.name == pageName,
      );
      if (pageItem.evaluate().isEmpty) {
        return;
      }

      expect(pageItem, findsOneWidget);

      // comment it out because it's not allowed to update the namespace in free plan
      // // set it to homepage
      // await tester.tapButton(
      //   find.textContaining(
      //     LocaleKeys.settings_sites_selectHomePage.tr(),
      //   ),
      // );
      // await tester.tapButton(
      //   find.descendant(
      //     of: find.byType(SelectHomePageMenu),
      //     matching: find.text(pageName),
      //   ),
      // );
      // await tester.pumpAndSettle();

      // // check if the page is set to homepage
      // final homePageItem = find.descendant(
      //   of: find.byType(DomainItem),
      //   matching: find.text(pageName),
      // );
      // expect(homePageItem, findsOneWidget);

      // // remove the homepage
      // await tester.tapButton(find.byType(DomainMoreAction));
      // await tester.tapButton(
      //   find.text(LocaleKeys.settings_sites_removeHomepage.tr()),
      // );
      // await tester.pumpAndSettle();

      // // check if the page is removed from homepage
      // expect(homePageItem, findsNothing);
    });

    testWidgets('update namespace', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // check if the page is published in sites page
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.sites);
      // wait the backend return the sites data
      await tester.wait(1000);

      // update the domain
      final domainMoreAction = find.byType(DomainMoreAction);
      await tester.tapButton(domainMoreAction);
      final updateNamespaceButton = find.text(
        LocaleKeys.settings_sites_updateNamespace.tr(),
      );
      await tester.pumpUntilFound(updateNamespaceButton);

      // click the update namespace button

      await tester.tapButton(updateNamespaceButton);

      // comment it out because it's not allowed to update the namespace in free plan
      // expect to see the dialog
      // await tester.updateNamespace('&&&???');

      // // need to upgrade to pro plan to update the namespace
      // final errorToast = find.text(
      //   LocaleKeys.settings_sites_error_proPlanLimitation.tr(),
      // );
      // await tester.pumpUntilFound(errorToast);
      // expect(errorToast, findsOneWidget);
      // await tester.pumpUntilNotFound(errorToast);

      // comment it out because it's not allowed to update the namespace in free plan
      // // short namespace
      // await tester.updateNamespace('a');

      // // expect to see the toast with error message
      // final errorToast2 = find.text(
      //   LocaleKeys.settings_sites_error_namespaceTooShort.tr(),
      // );
      // await tester.pumpUntilFound(errorToast2);
      // expect(errorToast2, findsOneWidget);
      // await tester.pumpUntilNotFound(errorToast2);
      // // valid namespace
      // await tester.updateNamespace('AppFlowy');

      // // expect to see the toast with success message
      // final successToast = find.text(
      //   LocaleKeys.settings_sites_success_namespaceUpdated.tr(),
      // );
      // await tester.pumpUntilFound(successToast);
      // expect(successToast, findsOneWidget);
    });

    testWidgets('''
More actions for published page:
1. visit site
2. copy link
3. settings
4. unpublish
5. custom url
''', (tester) async {
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
      await tester.tapButton(find.byType(PublishButton));

      // click empty area to close the publish menu
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      // check if the page is published in sites page
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.sites);
      // wait the backend return the sites data
      await tester.wait(2000);

      // check if the page is published in sites page
      final pageItem = find.byWidgetPredicate(
        (widget) =>
            widget is PublishedViewItem &&
            widget.publishInfoView.view.name == pageName,
      );
      expect(pageItem, findsOneWidget);

      final copyLinkItem = find.text(LocaleKeys.shareAction_copyLink.tr());
      final customUrlItem = find.text(LocaleKeys.settings_sites_customUrl.tr());
      final unpublishItem = find.text(LocaleKeys.shareAction_unPublish.tr());

      // custom url
      final publishMoreAction = find.byType(PublishedViewMoreAction);

      // click the copy link button
      {
        await tester.tapButton(publishMoreAction);
        await tester.pumpAndSettle();
        await tester.pumpUntilFound(copyLinkItem);
        await tester.tapButton(copyLinkItem);
        await tester.pumpAndSettle();
        await tester.pumpUntilNotFound(copyLinkItem);

        final clipboardContent = await getIt<ClipboardService>().getData();
        final plainText = clipboardContent.plainText;
        expect(
          plainText,
          contains(pageName),
        );
      }

      // custom url
      {
        await tester.tapButton(publishMoreAction);
        await tester.pumpAndSettle();
        await tester.pumpUntilFound(customUrlItem);
        await tester.tapButton(customUrlItem);
        await tester.pumpAndSettle();
        await tester.pumpUntilNotFound(customUrlItem);

        // see the custom url dialog
        final customUrlDialog = find.byType(PublishedViewSettingsDialog);
        expect(customUrlDialog, findsOneWidget);

        // rename the custom url
        final textField = find.descendant(
          of: customUrlDialog,
          matching: find.byType(TextField),
        );
        await tester.enterText(textField, 'hello-world');
        await tester.pumpAndSettle();

        // click the save button
        final saveButton = find.descendant(
          of: customUrlDialog,
          matching: find.text(LocaleKeys.button_save.tr()),
        );
        await tester.tapButton(saveButton);
        await tester.pumpAndSettle();

        // expect to see the toast with success message
        final successToast = find.text(
          LocaleKeys.settings_sites_success_updatePathNameSuccess.tr(),
        );
        await tester.pumpUntilFound(successToast);
        expect(successToast, findsOneWidget);
      }

      // unpublish
      {
        await tester.tapButton(publishMoreAction);
        await tester.pumpAndSettle();
        await tester.pumpUntilFound(unpublishItem);
        await tester.tapButton(unpublishItem);
        await tester.pumpAndSettle();
        await tester.pumpUntilNotFound(unpublishItem);

        // expect to see the toast with success message
        final successToast = find.text(
          LocaleKeys.publish_unpublishSuccessfully.tr(),
        );
        await tester.pumpUntilFound(successToast);
        expect(successToast, findsOneWidget);
        await tester.pumpUntilNotFound(successToast);

        // check if the page is unpublished in sites page
        expect(pageItem, findsNothing);
      }
    });
  });
}
