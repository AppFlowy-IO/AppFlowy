import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/base/built_in_page_widget.dart';
import 'package:appflowy/user/presentation/folder/folder_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter/services.dart';
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

      await tester.expectToSeeWelcomePage();

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
      await tester.expectToSeeWelcomePage();

      await TestFolder.cleanTestLocation(folderName);
    });

    testWidgets('switch to B from A, then switch to A again', (tester) async {
      const String userA = 'userA';
      const String userB = 'userB';

      await TestFolder.cleanTestLocation(userA);
      await TestFolder.setTestLocation(userA);

      await tester.initializeAppFlowy();

      await tester.tapGoButton();
      await tester.expectToSeeWelcomePage();

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
        await tester.expectToSeeWelcomePage();
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
        await tester.expectToSeeWelcomePage();
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
        await tester.expectToSeeWelcomePage();
        expect(find.textContaining(userB), findsOneWidget);
      }

      await TestFolder.cleanTestLocation(userA);
      await TestFolder.cleanTestLocation(userB);
    });

    testWidgets('reset to default location', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapGoButton();

      // home and readme document
      await tester.expectToSeeWelcomePage();

      // open settings and restore the location
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.files);
      await tester.restoreLocation();

      expect(
        await TestFolder.defaultDevelopmentLocation(),
        await TestFolder.currentLocation(),
      );
    });

    testWidgets('/board shortcut creates a new board', (tester) async {
      const folderName = 'appflowy';
      await TestFolder.cleanTestLocation(folderName);
      await TestFolder.setTestLocation(folderName);

      await tester.initializeAppFlowy();

      // tap open button
      await mockGetDirectoryPath(folderName);
      await tester.tapOpenFolderButton();

      await tester.wait(1000);
      await tester.expectToSeeWelcomePage();

      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      // Necessary for being able to enterText when not in debug mode
      binding.testTextInput.register();

      // Needs tab to obtain focus for the app flowy editor.
      // by default the tap appears at the center of the widget.
      final Finder editor = find.byType(AppFlowyEditor);
      await tester.tap(editor);
      await tester.pumpAndSettle();

      // tester.sendText() cannot be used since the editor
      // does not contain any EditableText widgets.
      // to interact with the app during an integration test,
      // simulate physical keyboard events.
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.slash);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyO);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Checks whether the options in the selection menu
      // for /board exist.
      expect(find.byType(SelectionMenuItemWidget), findsAtLeastNWidgets(2));

      // Finalizes the slash command that creates the board.
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Checks whether new board is referenced and properly on the page.
      expect(find.byType(BuiltInPageWidget), findsOneWidget);

      // Checks whether the new board is in the side bar.
      final sidebarLabel = LocaleKeys.newPageText.tr();
      expect(find.text(sidebarLabel), findsOneWidget);
    });

    testWidgets('/grid shortcut creates a new grid', (tester) async {
      const folderName = 'appflowy';
      await TestFolder.cleanTestLocation(folderName);
      await TestFolder.setTestLocation(folderName);

      await tester.initializeAppFlowy();

      // tap open button
      await mockGetDirectoryPath(folderName);
      await tester.tapOpenFolderButton();

      await tester.wait(1000);
      await tester.expectToSeeWelcomePage();

      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      // Necessary for being able to enterText when not in debug mode
      binding.testTextInput.register();

      // Needs tab to obtain focus for the app flowy editor.
      // by default the tap appears at the center of the widget.
      final Finder editor = find.byType(AppFlowyEditor);
      await tester.tap(editor);
      await tester.pumpAndSettle();

      // tester.sendText() cannot be used since the editor
      // does not contain any EditableText widgets.
      // to interact with the app during an integration test,
      // simulate physical keyboard events.
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.slash);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Checks whether the options in the selection menu
      // for /grid exist.
      expect(find.byType(SelectionMenuItemWidget), findsAtLeastNWidgets(2));

      // Finalizes the slash command that creates the board.
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Checks whether new board is referenced and properly on the page.
      expect(find.byType(BuiltInPageWidget), findsOneWidget);

      // Checks whether the new board is in the side bar.
      final sidebarLabel = LocaleKeys.newPageText.tr();
      expect(find.text(sidebarLabel), findsOneWidget);
    });
  });
}
