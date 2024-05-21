import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MoreViewActions', () {
    testWidgets('can duplicate and delete from menu', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.pumpAndSettle();

      final pageFinder = find.byType(ViewItem);
      expect(pageFinder, findsNWidgets(1));

      // Duplicate
      await tester.openMoreViewActions();
      await tester.duplicateByMoreViewActions();

      expect(pageFinder, findsNWidgets(2));

      // Delete
      await tester.openMoreViewActions();
      await tester.deleteByMoreViewActions();

      expect(pageFinder, findsNWidgets(1));
    });
  });
}
