import 'package:appflowy/user/presentation/folder/folder_widget.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
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

    testWidgets(
        'customize folder name and path when launching app in first time',
        (tester) async {
      const folderName = 'appflowy';
      await TestFolder.cleanTestLocation(folderName);

      await tester.initializeAppFlowy();

      // Click create button
      await tester.tapCreateButton();

      // Set directory
      final cfw = find.byType(CreateFolderWidget);
      expect(cfw, findsOneWidget);
      final state = tester.state(cfw) as CreateFolderWidgetState;
      final dir = await TestFolder.testLocation(null);
      state.directory = dir.path;

      // input folder name
      final ftf = find.byType(FlowyTextField);
      expect(ftf, findsOneWidget);
      await tester.enterText(ftf, 'appflowy');

      // Click create button again
      await tester.tapCreateButton();

      tester.expectToSeeWelcomePage();

      await TestFolder.cleanTestLocation(folderName);
    });

    testWidgets('open a new folder when launching app in first time',
        (tester) async {
      const folderName = 'appflowy';
      await TestFolder.cleanTestLocation(folderName);
      await TestFolder.setTestLocation(folderName);

      await tester.initializeAppFlowy();

      // tap open button
      await mockGetDirectoryPath(folderName);
      await tester.tapOpenFolderButton();

      await tester.wait(1000);
      tester.expectToSeeWelcomePage();

      await TestFolder.cleanTestLocation(folderName);
    });

    testWidgets('switch to B from A, then switch to A again', (tester) async {
      const String userA = 'userA';
      const String userB = 'userB';

      await TestFolder.cleanTestLocation(userA);
      await TestFolder.setTestLocation(userA);

      await tester.initializeAppFlowy();

      await tester.tapGoButton();
      tester.expectToSeeWelcomePage();

      // switch to user B
      {
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
      }

      // switch to the userA
      {
        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.user);
        await tester.enterUserName(userB);

        await tester.openSettingsPage(SettingsPage.files);
        await tester.pumpAndSettle();

        // mock the file_picker result
        await mockGetDirectoryPath(userA);
        await tester.tapCustomLocationButton();

        await tester.pumpAndSettle();
        tester.expectToSeeWelcomePage();
        expect(find.textContaining(userA), findsOneWidget);
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
        expect(find.textContaining(userB), findsOneWidget);
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
