import 'package:appflowy/plugins/document/presentation/editor_plugins/base/built_in_page_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

/// Integration tests for an empty document. The [TestWorkspaceService] will load a workspace from an empty document `assets/test/workspaces/empty_document.zip` for all tests.
///
/// To create another integration test with a preconfigured workspace. Use the following steps:
/// 1. Create a new workspace from the AppFlowy launch screen.
/// 2. Modify the workspace until it is suitable as the starting point for the integration test you need to land.
/// 3. Use a zip utility program to zip the workspace folder that you created.
/// 4. Add the zip file under `assets/test/workspaces/`
/// 5. Add a new enumeration to [TestWorkspace] in `integration_test/utils/data.dart`. For example, if you added a workspace called `empty_calendar.zip`, then [TestWorkspace] should have the following value:
/// ```dart
/// enum TestWorkspace {
///   board('board'),
///   empty_calendar('empty_calendar');
///
///   /* code */
/// }
/// ```
/// 6. Double check that the .zip file that you added is included as an asset in the pubspec.yaml file under appflowy_flutter.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const service = TestWorkspaceService(TestWorkspace.emptyDocument);

  group('Tests on a workspace with only an empty document', () {
    setUpAll(() async => service.setUpAll());
    setUp(() async => service.setUp());

    testWidgets('/board shortcut creates a new board and view of the board',
        (tester) async {
      await tester.initializeAppFlowy();

      // Needs tab to obtain focus for the app flowy editor.
      // by default the tap appears at the center of the widget.
      final Finder editor = find.byType(AppFlowyEditor);
      await tester.tap(editor);
      await tester.pumpAndSettle();

      // tester.sendText() cannot be used since the editor
      // does not contain any EditableText widgets.
      // to interact with the app during an integration test,
      // simulate physical keyboard events.
      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          LogicalKeyboardKey.slash,
          LogicalKeyboardKey.keyB,
          LogicalKeyboardKey.keyO,
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.keyR,
          LogicalKeyboardKey.keyD,
          LogicalKeyboardKey.arrowDown,
        ],
        tester: tester,
      );

      // Checks whether the options in the selection menu
      // for /board exist.
      expect(find.byType(SelectionMenuItemWidget), findsAtLeastNWidgets(2));

      // Finalizes the slash command that creates the board.
      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          LogicalKeyboardKey.enter,
        ],
        tester: tester,
      );

      // Checks whether new board is referenced and properly on the page.
      expect(find.byType(BuiltInPageWidget), findsOneWidget);

      // Checks whether the new database was created
      const newBoardLabel = "Untitled";
      expect(find.text(newBoardLabel), findsOneWidget);

      // Checks whether a view of the database was created
      const viewOfBoardLabel = "View of Untitled";
      expect(find.text(viewOfBoardLabel), findsNWidgets(2));
    });

    testWidgets('/grid shortcut creates a new grid and view of the grid',
        (tester) async {
      await tester.initializeAppFlowy();

      // Needs tab to obtain focus for the app flowy editor.
      // by default the tap appears at the center of the widget.
      final Finder editor = find.byType(AppFlowyEditor);
      await tester.tap(editor);
      await tester.pumpAndSettle();

      // tester.sendText() cannot be used since the editor
      // does not contain any EditableText widgets.
      // to interact with the app during an integration test,
      // simulate physical keyboard events.
      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          LogicalKeyboardKey.slash,
          LogicalKeyboardKey.keyG,
          LogicalKeyboardKey.keyR,
          LogicalKeyboardKey.keyI,
          LogicalKeyboardKey.keyD,
          LogicalKeyboardKey.arrowDown,
        ],
        tester: tester,
      );

      // Checks whether the options in the selection menu
      // for /grid exist.
      expect(find.byType(SelectionMenuItemWidget), findsAtLeastNWidgets(2));

      // Finalizes the slash command that creates the board.
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Checks whether new board is referenced and properly on the page.
      expect(find.byType(BuiltInPageWidget), findsOneWidget);

      // Checks whether the new database was created
      const newTableLabel = "Untitled";
      expect(find.text(newTableLabel), findsOneWidget);

      // Checks whether a view of the database was created
      const viewOfTableLabel = "View of Untitled";
      expect(find.text(viewOfTableLabel), findsNWidgets(2));
    });
  });
}
