import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'util/keyboard.dart';
import 'util/util.dart';

/// Integration tests for command shortcuts. Currently, shortcuts are tested on the empty document. The [TestWorkspaceService] will load a workspace from an empty document `assets/test/workspaces/empty_document.zip` for all tests.
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

  group('Command shortcut tests on a workspace with only an empty document',
      () {
    setUpAll(() async => await service.setUpAll());
    setUp(() async => await service.setUp());

    testWidgets('cmd/ctrl+shift+e shortcut toggles emoji picker',
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
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyE,
        ],
        tester: tester,
      );

      // Checks whether emoji selection menu is shown.
      expect(find.byType(EmojiSelectionMenu), findsOneWidget);
    });
  });
}
