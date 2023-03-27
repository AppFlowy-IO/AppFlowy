import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const service = TestWorkspaceService(TestWorkspace.board);

  group('board', () {
    setUpAll(() async => await service.setUpAll());
    setUp(() async => await service.setUp());

    testWidgets(
        'integration test unzips the proper workspace and loads it correctly.',
        (tester) async {
      await tester.initializeAppFlowy();
      expect(find.byType(AppFlowyBoard), findsOneWidget);
    });
  });
}
