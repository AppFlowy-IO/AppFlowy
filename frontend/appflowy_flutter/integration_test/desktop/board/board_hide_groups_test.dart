import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_hidden_groups.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board group options:', () {
    testWidgets('expand/collapse hidden groups', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      final collapseFinder = find.byFlowySvg(FlowySvgs.pull_left_outlined_s);
      final expandFinder = find.byFlowySvg(FlowySvgs.hamburger_s_s);

      // Is expanded by default
      expect(collapseFinder, findsOneWidget);
      expect(expandFinder, findsNothing);

      // Collapse hidden groups
      await tester.tap(collapseFinder);
      await tester.pumpAndSettle();

      // Is collapsed
      expect(collapseFinder, findsNothing);
      expect(expandFinder, findsOneWidget);

      // Expand hidden groups
      await tester.tap(expandFinder);
      await tester.pumpAndSettle();

      // Is expanded
      expect(collapseFinder, findsOneWidget);
      expect(expandFinder, findsNothing);
    });

    testWidgets('hide first group, and show it again', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      // Tap the options of the first group
      final optionsFinder = find
          .descendant(
            of: find.byType(BoardColumnHeader),
            matching: find.byFlowySvg(FlowySvgs.details_horizontal_s),
          )
          .first;

      await tester.tap(optionsFinder);
      await tester.pumpAndSettle();

      // Tap the hide option
      await tester.tap(find.byFlowySvg(FlowySvgs.hide_s));
      await tester.pumpAndSettle();

      int shownGroups =
          tester.widgetList(find.byType(BoardColumnHeader)).length;

      // We still show Doing, Done, No Status
      expect(shownGroups, 3);

      final hiddenCardFinder = find.byType(HiddenGroupCard);
      await tester.hoverOnWidget(hiddenCardFinder);
      await tester.tap(find.byFlowySvg(FlowySvgs.show_m));
      await tester.pumpAndSettle();

      shownGroups = tester.widgetList(find.byType(BoardColumnHeader)).length;
      expect(shownGroups, 4);
    });

    testWidgets('delete a group', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      expect(tester.widgetList(find.byType(BoardColumnHeader)).length, 4);

      // tap group option button for the first group. Delete shouldn't show up
      await tester.tapButton(
        find
            .descendant(
              of: find.byType(BoardColumnHeader),
              matching: find.byFlowySvg(FlowySvgs.details_horizontal_s),
            )
            .first,
      );
      expect(find.byFlowySvg(FlowySvgs.delete_s), findsNothing);

      // dismiss the popup
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // tap group option button for the first group. Delete should show up
      await tester.tapButton(
        find
            .descendant(
              of: find.byType(BoardColumnHeader),
              matching: find.byFlowySvg(FlowySvgs.details_horizontal_s),
            )
            .at(1),
      );
      expect(find.byFlowySvg(FlowySvgs.delete_s), findsOneWidget);

      // Tap the delete button and confirm
      await tester.tapButton(find.byFlowySvg(FlowySvgs.delete_s));
      await tester.tapButtonWithName(LocaleKeys.space_delete.tr());

      // Expect number of groups to decrease by one
      expect(tester.widgetList(find.byType(BoardColumnHeader)).length, 3);
    });
  });
}
