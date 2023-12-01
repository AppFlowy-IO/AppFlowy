import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_property.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appflowy_board/appflowy_board.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board group test', () {
    testWidgets('move row to another group', (tester) async {
      const card1Name = 'Card 1';
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Board);
      final card1 = find.ancestor(
        of: find.findTextInFlowyText(card1Name), 
        matching: find.byType(AppFlowyGroupCard),
      );
      final doingGroup = find.findTextInFlowyText('Doing');
      final doingGroupCenter = tester.getCenter(doingGroup);
      final card1Center = tester.getCenter(card1);

      await tester.timedDrag(
        card1, 
        doingGroupCenter.translate(-card1Center.dx, -card1Center.dy),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      await tester.tap(card1);
      await tester.pumpAndSettle();

      final card1StatusFinder = find.descendant(
        of: find.byType(RowPropertyList), 
        matching: find.descendant(
          of: find.byType(SelectOptionTag), 
          matching: find.byType(FlowyText),
        ),
      );
      expect(card1StatusFinder, findsNWidgets(1));
      final card1StatusText = tester.widget<FlowyText>(card1StatusFinder).text;
      expect(card1StatusText, 'Doing');
    });
  });
}
