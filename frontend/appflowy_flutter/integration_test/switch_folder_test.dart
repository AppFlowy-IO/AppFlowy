import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('customize the folder path', () {
    const location = 'appflowy';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(location);
    });

    tearDownAll(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('switch to B from A, then switch to A again', (tester) async {
      const String userA = 'userA';
      const String userB = 'userB';

      await TestFolder.cleanTestLocation(userA);
      await TestFolder.cleanTestLocation(userB);
      await TestFolder.setTestLocation(userA);

      await tester.initializeAppFlowy();

      await tester.tapGoButton();
      tester.expectToSeeWelcomePage();

      // switch to user B
      {
        // set user name to userA
        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.user);
        await tester.enterUserName(userA);

        await tester.openSettingsPage(SettingsPage.files);
        await tester.pumpAndSettle();

        // mock the file_picker result
        await mockGetDirectoryPath(userB);
        await tester.tapCustomLocationButton();
        await tester.pumpAndSettle();
        tester.expectToSeeWelcomePage();

        // set user name to userB
        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.user);
        await tester.enterUserName(userB);
      }

      // switch to the userA
      {
        await tester.openSettingsPage(SettingsPage.files);
        await tester.pumpAndSettle();

        // mock the file_picker result
        await mockGetDirectoryPath(userA);
        await tester.tapCustomLocationButton();

        await tester.pumpAndSettle();
        tester.expectToSeeWelcomePage();
        tester.expectToSeeUserName(userA);
      }

      // switch to the userB again
      {
        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.files);
        await tester.pumpAndSettle();

        // mock the file_picker result
        await mockGetDirectoryPath(userB);
        await tester.tapCustomLocationButton();

        await tester.pumpAndSettle();
        tester.expectToSeeWelcomePage();
        tester.expectToSeeUserName(userB);
      }

      await TestFolder.cleanTestLocation(userA);
      await TestFolder.cleanTestLocation(userB);
    });

    testWidgets('reset to default location', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapGoButton();

      // home and readme document
      tester.expectToSeeWelcomePage();

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
