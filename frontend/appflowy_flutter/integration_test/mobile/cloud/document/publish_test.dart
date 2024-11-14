import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
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
