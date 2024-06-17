import 'package:flutter/material.dart';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../shared/auth_operation.dart';
import '../shared/base.dart';
import '../shared/expectation.dart';
import '../shared/settings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('billing', () {
    testWidgets('can fetch subscription', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      await tester.openSettings();

      // Make sure the SettingsMenuElement button for billing
      // is scrolled into view
      final scrollable = find.descendant(
        of: find.byType(SettingsMenu),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text(LocaleKeys.settings_planPage_menuLabel.tr()),
        0,
        scrollable: scrollable,
      );

      await tester.openSettingsPage(SettingsPage.plan);
      await tester.pumpUntilNotFound(find.byType(CircularProgressIndicator));

      final freeSubscription = WorkspaceSubscriptionPB(
        workspaceId: '-',
        subscriptionPlan: SubscriptionPlanPB.None,
        isActive: true,
      );

      // We know the initial fetch went well or was handled correctly,
      // if the free label is displayed and upgrade button
      expect(find.text(freeSubscription.label), findsOneWidget);
      expect(
        find.text(
          LocaleKeys.settings_planPage_planUsage_currentPlan_upgrade.tr(),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          LocaleKeys.settings_planPage_planUsage_currentPlan_upgrade.tr(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPlanComparisonDialog), findsOneWidget);
    });
  });
}
