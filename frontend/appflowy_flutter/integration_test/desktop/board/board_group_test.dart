import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/select/select_option_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/row_property.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board group test:', () {
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

    testWidgets('rename group', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final headers = find.byType(BoardColumnHeader);
      expect(headers, findsNWidgets(4));

      // try to tap no status
      final noStatus = headers.first;
      expect(
        find.descendant(of: noStatus, matching: find.text("No Status")),
        findsOneWidget,
      );
      await tester.tapButton(noStatus);
      expect(
        find.descendant(of: noStatus, matching: find.byType(TextField)),
        findsNothing,
      );

      // tap on To Do and edit it
      final todo = headers.at(1);
      expect(
        find.descendant(of: todo, matching: find.text("To Do")),
        findsOneWidget,
      );
      await tester.tapButton(todo);
      await tester.enterText(
        find.descendant(of: todo, matching: find.byType(TextField)),
        "tada",
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final newHeaders = find.byType(BoardColumnHeader);
      expect(newHeaders, findsNWidgets(4));
      final tada = find.byType(BoardColumnHeader).at(1);
      expect(
        find.descendant(of: tada, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: tada,
          matching: find.text("tada"),
        ),
        findsOneWidget,
      );
    });

    testWidgets('edit select option from row detail', (tester) async {
      const card1Name = 'Card 1';

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      await tester.tapButton(
        find.descendant(
          of: find.byType(RowCard),
          matching: find.text(card1Name),
        ),
      );

      await tester.tapGridFieldWithNameInRowDetailPage("Status");
      await tester.tapButton(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectOptionTagCell && widget.option.name == "To Do",
        ),
      );
      final editor = find.byType(SelectOptionEditor);
      await tester.enterText(
        find.descendant(of: editor, matching: find.byType(TextField)),
        "tada",
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.dismissFieldEditor();
      await tester.dismissRowDetailPage();

      final newHeaders = find.byType(BoardColumnHeader);
      expect(newHeaders, findsNWidgets(4));
      final tada = find.byType(BoardColumnHeader).at(1);
      expect(
        find.descendant(of: tada, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: tada,
          matching: find.text("tada"),
        ),
        findsOneWidget,
      );
    });
  });
}
