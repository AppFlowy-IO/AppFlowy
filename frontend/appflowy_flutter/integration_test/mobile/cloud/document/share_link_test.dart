import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('share link:', () {
    testWidgets('copy share link and paste it on doc', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open the getting started page and paste the link
      await tester.openPage(Constants.gettingStartedPageName);

      // open the more action menu
      await tester.editor.openMoreActionMenuOnMobile();

      // click the share link item
      await tester.editor.clickMoreActionItemOnMobile(
        LocaleKeys.shareAction_copyLink.tr(),
      );

      // check the clipboard
      final content = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        content?.text,
        matches(appflowySharePageLinkPattern),
      );
    });
  });
}
