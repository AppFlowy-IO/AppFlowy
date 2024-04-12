import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
import '../../shared/expectation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const emoji = '😁';

  group('Icon', () {
    testWidgets('Update page icon in sidebar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create document, board, grid and calendar views
      for (final value in ViewLayoutPB.values) {
        await tester.createNewPageWithNameUnderParent(
          name: value.name,
          parentName: gettingStarted,
          layout: value,
        );

        // update its icon
        await tester.updatePageIconInSidebarByName(
          name: value.name,
          parentName: gettingStarted,
          layout: value,
          icon: emoji,
        );

        tester.expectViewHasIcon(
          value.name,
          value,
          emoji,
        );
      }
    });

    testWidgets('Update page icon in title bar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create document, board, grid and calendar views
      for (final value in ViewLayoutPB.values) {
        await tester.createNewPageWithNameUnderParent(
          name: value.name,
          parentName: gettingStarted,
          layout: value,
        );

        // update its icon
        await tester.updatePageIconInTitleBarByName(
          name: value.name,
          layout: value,
          icon: emoji,
        );

        tester.expectViewHasIcon(
          value.name,
          value,
          emoji,
        );

        tester.expectViewTitleHasIcon(
          value.name,
          value,
          emoji,
        );
      }
    });
  });
}
