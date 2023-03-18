import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/base/built_in_page_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';

import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('slash command tests', () {
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
  });
}
