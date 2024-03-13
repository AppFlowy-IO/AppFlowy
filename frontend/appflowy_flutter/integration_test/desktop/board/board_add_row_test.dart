import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/widgets/card/container/card_container.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

const defaultFirstCardName = 'Card 1';
const defaultLastCardName = 'Card 3';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board add row test:', () {
    testWidgets('from header', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final findFirstCard = find.descendant(
        of: find.byType(AppFlowyGroupCard),
        matching: find.byType(Text),
      );

      Text firstCardText = tester.firstWidget(findFirstCard);
      expect(firstCardText.data, defaultFirstCardName);

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
          of: find.byType(RowCardContainer),
          matching: find.byType(TextField),
        ),
        newCardName,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.byType(AppFlowyBoard));
      await tester.pumpAndSettle();

      firstCardText = tester.firstWidget(findFirstCard);
      expect(firstCardText.data, newCardName);
    });

    testWidgets('from footer', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final findLastCard = find.descendant(
        of: find.byType(AppFlowyGroupCard),
        matching: find.byType(Text),
      );

      Text? lastCardText = tester.widgetList(findLastCard).last as Text;
      expect(lastCardText.data, defaultLastCardName);

      await tester.tap(
        find
            .descendant(
              of: find.byType(AppFlowyGroupFooter),
              matching: find.byType(FlowySvg),
            )
            .at(1),
      );
      await tester.pumpAndSettle();

      const newCardName = 'Card 4';
      await tester.enterText(
        find.descendant(
          of: find.byType(RowCardContainer),
          matching: find.byType(TextField),
        ),
        newCardName,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.byType(AppFlowyBoard));
      await tester.pumpAndSettle();

      lastCardText = tester.widgetList(findLastCard).last as Text;
      expect(lastCardText.data, newCardName);
    });
  });
}
