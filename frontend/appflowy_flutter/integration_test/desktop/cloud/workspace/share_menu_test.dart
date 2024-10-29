// ignore_for_file: unused_import

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/constants.dart';
import '../../../shared/mock/mock_file_picker.dart';
import '../../../shared/util.dart';
import '../../../shared/workspace.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Share menu:', () {
    testWidgets('share tab', (tester) async {
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

      // click the share button
      await tester.tapShareButton();

      // expect the share menu is shown
      final shareMenu = find.byType(ShareMenu);
      expect(shareMenu, findsOneWidget);

      // click the copy link button
      final copyLinkButton = find.textContaining(
        LocaleKeys.button_copyLink.tr(),
      );
      await tester.tapButton(copyLinkButton);

      // read the clipboard content
      final clipboardContent = await getIt<ClipboardService>().getData();
      final plainText = clipboardContent.plainText;
      expect(
        plainText,
        matches(appflowySharePageLinkPattern),
      );

      final shareValues = plainText!
          .replaceAll('${ShareConstants.shareBaseUrl}/', '')
          .split('/');
      final workspaceId = shareValues[0];
      expect(workspaceId, isNotEmpty);
      final pageId = shareValues[1];
      expect(pageId, isNotEmpty);
    });
  });
}
