import 'package:appflowy/plugins/document/presentation/plugins/base/built_in_page_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const service = TestWorkspaceService(TestWorkspace.board);

  group('board', () {
    setUpAll(() async => await service.setUpAll());
    setUp(() async => await service.setUp());

    testWidgets('example',
        (tester) async {
      await tester.initializeAppFlowy();
      expect(find.byType(BuiltInPageWidget), findsOneWidget);
    });
  });
}
