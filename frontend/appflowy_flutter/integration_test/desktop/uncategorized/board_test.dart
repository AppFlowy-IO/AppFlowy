import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

/// Integration tests for an empty board. The [TestWorkspaceService] will load
/// a workspace from an empty board `assets/test/workspaces/board.zip` for all
/// tests.
///
/// To create another integration test with a preconfigured workspace.
/// Use the following steps.
/// 1. Create a new workspace from the AppFlowy launch screen.
/// 2. Modify the workspace until it is suitable as the starting point for
///    the integration test you need to land.
/// 3. Use a zip utility program to zip the workspace folder that you created.
/// 4. Add the zip file under `assets/test/workspaces/`
/// 5. Add a new enumeration to [TestWorkspace] in `integration_test/utils/data.dart`.
///    For example, if you added a workspace called `empty_calendar.zip`,
///    then [TestWorkspace] should have the following value:
/// ```dart
/// enum TestWorkspace {
///   board('board'),
///   empty_calendar('empty_calendar');
///
///   /* code */
/// }
/// ```
/// 6. Double check that the .zip file that you added is included as an asset in
///    the pubspec.yaml file under appflowy_flutter.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const service = TestWorkspaceService(TestWorkspace.board);

  group('board', () {
    setUpAll(() async => service.setUpAll());
    setUp(() async => service.setUp());

    testWidgets('open the board with data structure in v0.2.0', (tester) async {
      await tester.initializeAppFlowy();
      expect(find.byType(AppFlowyBoard), findsOneWidget);
    });
  });
}
