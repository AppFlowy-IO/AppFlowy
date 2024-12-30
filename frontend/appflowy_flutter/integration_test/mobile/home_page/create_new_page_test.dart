import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('create new page in home page:', () {
    testWidgets('create document', (tester) async {
      await tester.launchInAnonymousMode();

      // tap the create page button
      final createPageButton = find.byWidgetPredicate(
        (widget) =>
            widget is FlowySvg &&
            widget.svg.path == FlowySvgs.m_home_add_m.path,
      );
      await tester.tapButton(createPageButton);
      await tester.pumpAndSettle();
      expect(find.byType(MobileDocumentScreen), findsOneWidget);
    });
  });
}
