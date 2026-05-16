import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialog_v2.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Rename empty name view (untitled)', (tester) async {
    await tester.initializeAppFlowy(
      cloudType: AuthenticatorType.appflowyCloudSelfHost,
    );
    await tester.tapGoogleLoginInButton();
    await tester.expectToSeeHomePageWithGetStartedPage();

    await tester.createNewPageInSpace(
      spaceName: Constants.generalSpaceName,
      layout: ViewLayoutPB.Document,
    );

    // click the ... button and open rename dialog
    await tester.hoverOnPageName(
      ViewLayoutPB.Document.defaultName,
      onHover: () async {
        await tester.tapPageOptionButton();
        await tester.tapButtonWithName(
          LocaleKeys.disclosureAction_rename.tr(),
        );
      },
    );
    await tester.pumpAndSettle();

    expect(find.byType(AFTextFieldDialog), findsOneWidget);

    final textField = tester.widget<AFTextField>(
      find.descendant(
        of: find.byType(AFTextFieldDialog),
        matching: find.byType(AFTextField),
      ),
    );

    expect(
      textField.controller!.text,
      LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
    );
  });
}
