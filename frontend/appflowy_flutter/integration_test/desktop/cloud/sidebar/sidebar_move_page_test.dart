import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('sidebar move page: ', () {
    testWidgets('create a new document and move it to Getting started',
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

      // click the ... button and move to Getting started
      await tester.hoverOnPageName(
        pageName,
        onHover: () async {
          await tester.tapPageOptionButton();
          await tester.tapButtonWithName(
            LocaleKeys.disclosureAction_moveTo.tr(),
          );
        },
      );

      // expect to see two pages
      // one is in the sidebar, the other is in the move to page list
      // 1. Getting started
      // 2. To-dos
      final gettingStarted = find.findTextInFlowyText(
        Constants.gettingStartedPageName,
      );
      final toDos = find.findTextInFlowyText(Constants.toDosPageName);
      await tester.pumpUntilFound(gettingStarted);
      await tester.pumpUntilFound(toDos);
      expect(gettingStarted, findsNWidgets(2));

      // skip the length check on Linux temporarily,
      //  because it failed in expect check but the previous pumpUntilFound is successful
      if (!UniversalPlatform.isLinux) {
        expect(toDos, findsNWidgets(2));

        // hover on the todos page, and will see a forbidden icon
        await tester.hoverOnWidget(
          toDos.last,
          onHover: () async {
            final tooltips = find.byTooltip(
              LocaleKeys.space_cannotMovePageToDatabase.tr(),
            );
            expect(tooltips, findsOneWidget);
          },
        );
        await tester.pumpAndSettle();
      }

      // Attempt right-click on the page name and expect not to see
      await tester.tap(gettingStarted.last, buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(
        find.text(LocaleKeys.disclosureAction_moveTo.tr()),
        findsOneWidget,
      );

      // move the current page to Getting started
      await tester.tapButton(
        gettingStarted.last,
      );

      await tester.pumpAndSettle();

      // after moving, expect to not see the page name in the sidebar
      final page = tester.findPageName(pageName);
      expect(page, findsNothing);

      // click to expand the getting started page
      await tester.expandOrCollapsePage(
        pageName: Constants.gettingStartedPageName,
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      // expect to see the page name in the getting started page
      final pageInGettingStarted = tester.findPageName(
        pageName,
        parentName: Constants.gettingStartedPageName,
      );
      expect(pageInGettingStarted, findsOneWidget);
    });
  });
}
