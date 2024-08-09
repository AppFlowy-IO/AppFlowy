import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/widgets/row/row_property.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';

import '../../shared/util.dart';
import '../../shared/database_test_op.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board group test', () {
    testWidgets('move row to another group', (tester) async {
      const card1Name = 'Card 1';
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      final card1 = find.ancestor(
        of: find.text(card1Name),
        matching: find.byType(RowCard),
      );
      final doingGroup = find.text('Doing');
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
          matching: find.byType(Text),
        ),
      );
      expect(card1StatusFinder, findsNWidgets(1));
      final card1StatusText = tester.widget<Text>(card1StatusFinder).data;
      expect(card1StatusText, 'Doing');
    });

    testWidgets('add new group', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      // assert number of groups
      tester.assertNumberOfGroups(4);

      // scroll the board horizontally to ensure add new group button appears
      await tester.scrollBoardToEnd();

      // assert and click on add new group button
      tester.assertNewGroupTextField(false);
      await tester.tapNewGroupButton();
      tester.assertNewGroupTextField(true);

      // enter new group name and submit
      await tester.enterNewGroupName('needs design', submit: true);

      // assert number of groups has increased
      tester.assertNumberOfGroups(5);

      // assert text field has disappeared
      await tester.scrollBoardToEnd();
      tester.assertNewGroupTextField(false);

      // click on add new group button
      await tester.tapNewGroupButton();
      tester.assertNewGroupTextField(true);

      // type some things
      await tester.enterNewGroupName('needs planning', submit: false);

      // click on clear button and assert empty contents
      await tester.clearNewGroupTextField();

      // press escape to cancel
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      tester.assertNewGroupTextField(false);

      // click on add new group button
      await tester.tapNewGroupButton();
      tester.assertNewGroupTextField(true);

      // press elsewhere to cancel
      await tester.tap(find.byType(AppFlowyBoard));
      await tester.pumpAndSettle();
      tester.assertNewGroupTextField(false);
    });
  });
}
