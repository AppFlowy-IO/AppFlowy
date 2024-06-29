import 'dart:ui' as ui;

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/row_banner.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board row test', () {
    testWidgets('delete item in ToDo card', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      const name = 'Card 1';
      final card1 = find.text(name);
      await tester.hoverOnWidget(
        card1,
        onHover: () async {
          final moreOption = find.byType(MoreCardOptionsAccessory);
          await tester.tapButton(moreOption);
        },
      );
      await tester.tapButtonWithName(LocaleKeys.button_delete.tr());
      await tester.tapOKButton();
      expect(find.text(name), findsNothing);
    });

    testWidgets('duplicate item in ToDo card', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      const name = 'Card 1';
      final card1 = find.text(name);
      await tester.hoverOnWidget(
        card1,
        onHover: () async {
          final moreOption = find.byType(MoreCardOptionsAccessory);
          await tester.tapButton(moreOption);
        },
      );
      await tester.tapButtonWithName(LocaleKeys.button_duplicate.tr());
      expect(find.textContaining(name, findRichText: true), findsNWidgets(2));
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

    testWidgets('auto direction card title', (tester) async {
      const card1Name = 'Card 1';
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.setDefaultTextDirection(AppFlowyTextDirection.auto);

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      final card1 = find.ancestor(
        of: find.text(card1Name),
        matching: find.byType(RowCard),
      );

      await tester.tap(card1);
      await tester.pumpAndSettle();

      var cardTitleTextField = find.descendant(
        of: find.byType(RowBanner),
        matching: find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == card1Name,
        ),
      );
      expect(cardTitleTextField, findsOne);
      var cardTitleTextFieldWidget =
          tester.widget(cardTitleTextField) as TextField;

      await tester.tap(cardTitleTextField);
      await tester.ctrlABackspace();
      expect(cardTitleTextFieldWidget.textDirection, ui.TextDirection.ltr);

      cardTitleTextField = find.descendant(
        of: find.byType(RowBanner),
        matching: find.byType(TextField),
        matchRoot: true,
      );
      await tester.enterText(cardTitleTextField, "کارت ۱");
      var editableTextCell = find.descendant(
        of: find.byType(RowBanner),
        matching: find.byType(EditableTextCell),
        matchRoot: true,
      );
      var editableTextCellState =
          tester.state(editableTextCell) as EditableTextCellState;
      editableTextCellState.cellBloc.add(
        const TextCellEvent.didReceiveCellUpdate("کارت ۱"),
      );
      await tester.pumpAndSettle();

      cardTitleTextFieldWidget = tester.widget<TextField>(
        find.descendant(
          of: find.byType(RowBanner),
          matching: find.byType(TextField),
          matchRoot: true,
        ),
      );
      expect(cardTitleTextFieldWidget.textDirection, ui.TextDirection.rtl);

      await tester.ctrlABackspace();
      cardTitleTextField = find.descendant(
        of: find.byType(RowBanner),
        matching: find.byType(TextField),
        matchRoot: true,
      );
      await tester.enterText(cardTitleTextField, card1Name);
      editableTextCell = find.descendant(
        of: find.byType(RowBanner),
        matching: find.byType(EditableTextCell),
        matchRoot: true,
      );
      editableTextCellState =
          tester.state(editableTextCell) as EditableTextCellState;
      editableTextCellState.cellBloc.add(
        const TextCellEvent.didReceiveCellUpdate(card1Name),
      );
      await tester.pumpAndSettle();

      cardTitleTextFieldWidget = tester.widget<TextField>(
        find.descendant(
          of: find.byType(RowBanner),
          matching: find.byType(TextField),
          matchRoot: true,
        ),
      );
      expect(cardTitleTextFieldWidget.textDirection, ui.TextDirection.ltr);
    });
  });
}
