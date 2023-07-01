import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('customize the folder path', () {
    testWidgets('switch to B from A, then switch to A again', (tester) async {
      final userA = uuid();
      final userB = uuid();

      final context = await tester.initializeAppFlowy();
      await TestFolder.setTestLocation(
        context.applicationDataDirectory.path,
        name: userA,
      );

      await tester.tapGoButton();
      tester.expectToSeeHomePage();

      // switch to user B
      {
        // set user name for userA
        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.user);
        await tester.enterUserName(userA);

        await tester.openSettingsPage(SettingsPage.files);
        await tester.pumpAndSettle();

        // mock the file_picker result
        await mockGetDirectoryPath(
          context.applicationDataDirectory.path,
          userB,
        );
        await tester.tapCustomLocationButton();
        await tester.pumpAndSettle();
        tester.expectToSeeHomePage();

        // set user name for userB
        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.user);
        await tester.enterUserName(userB);
      }

      // switch to the userA
      {
        await tester.openSettingsPage(SettingsPage.files);
        await tester.pumpAndSettle();

        // mock the file_picker result
        await mockGetDirectoryPath(
          context.applicationDataDirectory.path,
          userA,
        );
        await tester.tapCustomLocationButton();

        await tester.pumpAndSettle();
        tester.expectToSeeHomePage();
        tester.expectToSeeUserName(userA);
      }

      // switch to the userB again
      {
        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.files);
        await tester.pumpAndSettle();

        // mock the file_picker result
        await mockGetDirectoryPath(
          context.applicationDataDirectory.path,
          userB,
        );
        await tester.tapCustomLocationButton();

        await tester.pumpAndSettle();
        tester.expectToSeeHomePage();
        tester.expectToSeeUserName(userB);
      }
    });

    testWidgets('reset to default location', (tester) async {
      final context = await tester.initializeAppFlowy();
      await TestFolder.setTestLocation(context.applicationDataDirectory.path);

      await tester.tapGoButton();

      // home and readme document
      tester.expectToSeeHomePage();

      // open settings and restore the location
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.files);
      await tester.restoreLocation();

      expect(
        await TestFolder.defaultDevelopmentLocation(),
        await TestFolder.currentLocation(),
      );
    });
  });
}
