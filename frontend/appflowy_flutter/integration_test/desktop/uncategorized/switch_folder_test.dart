import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('customize the folder path', () {
    if (Platform.isWindows) {
      return;
    }

    // testWidgets('switch to B from A, then switch to A again', (tester) async {
    //   const userA = 'UserA';
    //   const userB = 'UserB';

    //   final initialPath = p.join(userA, appFlowyDataFolder);
    //   final context = await tester.initializeAppFlowy(
    //     pathExtension: initialPath,
    //   );
    //   // remove the last extension
    //   final rootPath = context.applicationDataDirectory.replaceFirst(
    //     initialPath,
    //     '',
    //   );

    //   await tester.tapGoButton();
    //   await tester.expectToSeeHomePageWithGetStartedPage();

    //   // switch to user B
    //   {
    //     // set user name for userA
    //     await tester.openSettings();
    //     await tester.openSettingsPage(SettingsPage.user);
    //     await tester.enterUserName(userA);

    //     await tester.openSettingsPage(SettingsPage.files);
    //     await tester.pumpAndSettle();

    //     // mock the file_picker result
    //     await mockGetDirectoryPath(
    //       p.join(rootPath, userB),
    //     );
    //     await tester.tapCustomLocationButton();
    //     await tester.pumpAndSettle();
    //     await tester.expectToSeeHomePageWithGetStartedPage();

    //     // set user name for userB
    //     await tester.openSettings();
    //     await tester.openSettingsPage(SettingsPage.user);
    //     await tester.enterUserName(userB);
    //   }

    //   // switch to the userA
    //   {
    //     await tester.openSettingsPage(SettingsPage.files);
    //     await tester.pumpAndSettle();

    //     // mock the file_picker result
    //     await mockGetDirectoryPath(
    //       p.join(rootPath, userA),
    //     );
    //     await tester.tapCustomLocationButton();

    //     await tester.pumpAndSettle();
    //     await tester.expectToSeeHomePageWithGetStartedPage();
    //     tester.expectToSeeUserName(userA);
    //   }

    //   // switch to the userB again
    //   {
    //     await tester.openSettings();
    //     await tester.openSettingsPage(SettingsPage.files);
    //     await tester.pumpAndSettle();

    //     // mock the file_picker result
    //     await mockGetDirectoryPath(
    //       p.join(rootPath, userB),
    //     );
    //     await tester.tapCustomLocationButton();

    //     await tester.pumpAndSettle();
    //     await tester.expectToSeeHomePageWithGetStartedPage();
    //     tester.expectToSeeUserName(userB);
    //   }
    // });

    testWidgets('reset to default location', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapGoButton();

      // home and readme document
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open settings and restore the location
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.files);
      await tester.restoreLocation();

      expect(
        await appFlowyApplicationDataDirectory().then((value) => value.path),
        await getIt<ApplicationDataStorage>().getPath(),
      );
    });
  });
}
