import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import '../../shared/util.dart';
import '../../shared/database_test_op.dart';

const defaultFirstCardName = 'Card 1';
const defaultLastCardName = 'Card 3';

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

    testWidgets('on adding row fetch url meta data', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final card1 = find.text('Card 1');
      await tester.tapButton(card1);
      const urlFieldName = 'url';
      await tester.createField(
        FieldType.URL,
        name: urlFieldName,
        layout: ViewLayoutPB.Board,
      );
      await tester.dismissRowDetailPage();

      await tester.tapDatabaseSettingButton();
      await tester.tapDatabaseGroupSettingsButton();
      await tester.toggleFetchURLMetaData();
      await tester.tapButtonWithName(LocaleKeys.board_urlFieldToFill.tr());
      final findListView = find.ancestor(
        of: find.text(LocaleKeys.board_urlFieldNone.tr()),
        matching: find.byType(ListView),
      );
      await tester.tapButton(
        find.descendant(of: findListView, matching: find.text(urlFieldName)),
      );
      await tester.dismissRowDetailPage();

      await tester.tapButton(
        find.byType(BoardColumnFooter).at(1),
      );

      const newCardName = 'https://appflowy.io/';
      await tester.enterText(
        find.descendant(
          of: find.byType(BoardColumnFooter),
          matching: find.byType(TextField),
        ),
        newCardName,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 3000));

      await tester.tap(find.byType(AppFlowyBoard));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(RowCard).last,
          matching: find.text("AppFlowy.IO"),
        ),
        findsOneWidget,
      );
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
