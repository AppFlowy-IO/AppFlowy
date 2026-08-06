import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

const defaultFirstCardName = 'Card 1';
const defaultLastCardName = 'Card 3';

Finder _footerTextField() => find.descendant(
      of: find.byType(BoardColumnFooter).at(1),
      matching: find.byType(TextField),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board add row test:', () {
    testWidgets('from header', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final firstCard = find.byType(RowCard).first;

      expect(
        find.descendant(
          of: firstCard,
          matching: find.text(defaultFirstCardName),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find
            .descendant(
              of: find.byType(BoardColumnHeader),
              matching: find.byWidgetPredicate(
                (widget) => widget is FlowySvg && widget.svg == FlowySvgs.add_s,
              ),
            )
            .at(1),
      );
      await tester.pumpAndSettle();

      const newCardName = 'Card 4';
      await tester.enterText(
        find.descendant(
          of: firstCard,
          matching: find.byType(TextField),
        ),
        newCardName,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.byType(AppFlowyBoard));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(RowCard).first,
          matching: find.text(newCardName),
        ),
        findsOneWidget,
      );
    });

    testWidgets('from footer', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final lastCard = find.byType(RowCard).last;

      expect(
        find.descendant(
          of: lastCard,
          matching: find.text(defaultLastCardName),
        ),
        findsOneWidget,
      );

      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );

      const newCardName = 'Card 4';
      await tester.enterText(
        find.descendant(
          of: find.byType(BoardColumnFooter),
          matching: find.byType(TextField),
        ),
        newCardName,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.byType(AppFlowyBoard));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(RowCard).last,
          matching: find.text(newCardName),
        ),
        findsOneWidget,
      );
    });

    testWidgets('footer: empty title submit does not create a card',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final cardsBefore = find.byType(RowCard).evaluate().length;

      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );

      await tester.showKeyboard(_footerTextField());
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byType(RowCard).evaluate().length, cardsBefore);
    });

    testWidgets(
        'footer: clicking outside cancels creation and clears the draft',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final cardsBefore = find.byType(RowCard).evaluate().length;

      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );

      const draft = 'abc';
      await tester.enterText(_footerTextField(), draft);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Click outside the input: start creating a card in another column.
      await tester.tapButton(
        find.byType(BoardColumnFooter).at(0),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // No card was created and the draft is gone.
      expect(find.byType(RowCard).evaluate().length, cardsBefore);
      expect(find.text(draft), findsNothing);

      // Reopening the input must show a clean, empty text field.
      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );
      final reopened = tester.widget<TextField>(_footerTextField());
      expect(reopened.controller!.text, isEmpty);
    });

    testWidgets('footer: escape cancels creation and clears the draft',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final cardsBefore = find.byType(RowCard).evaluate().length;

      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );

      const draft = 'abc';
      await tester.enterText(_footerTextField(), draft);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // No card was created and the draft is gone.
      expect(find.byType(RowCard).evaluate().length, cardsBefore);
      expect(find.text(draft), findsNothing);

      // Reopening the input must show a clean, empty text field.
      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );
      final reopened = tester.widget<TextField>(_footerTextField());
      expect(reopened.controller!.text, isEmpty);
    });

    testWidgets('footer: pressing enter twice creates only one card',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final cardsBefore = find.byType(RowCard).evaluate().length;

      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );

      const newCardName = 'Card 4';
      await tester.enterText(_footerTextField(), newCardName);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byType(RowCard).evaluate().length, cardsBefore + 1);
      expect(
        find.descendant(
          of: find.byType(RowCard).last,
          matching: find.text(newCardName),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'footer: submitting then clicking outside does not create a duplicate',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final cardsBefore = find.byType(RowCard).evaluate().length;

      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );

      const newCardName = 'Card 4';
      await tester.enterText(_footerTextField(), newCardName);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // The input stays open after submitting; clicking outside must not
      // submit the (now cleared) draft a second time.
      await tester.tapButton(
        find.byType(BoardColumnFooter).at(0),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byType(RowCard).evaluate().length, cardsBefore + 1);
      expect(
        find.descendant(
          of: find.byType(RowCard).last,
          matching: find.text(newCardName),
        ),
        findsOneWidget,
      );
    });
  });
}
