import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database_view/board/presentation/widgets/board_hidden_groups.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board hide groups test', () {
    testWidgets('expand/collapse hidden groups', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      await tester.createNewPageWithName(layout: ViewLayoutPB.Board);

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
      await tester.tapGoButton();
      await tester.createNewPageWithName(layout: ViewLayoutPB.Board);

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
  });
}

extension FlowySvgFinder on CommonFinders {
  Finder byFlowySvg(FlowySvgData svg) => _FlowySvgFinder(svg);
}

class _FlowySvgFinder extends MatchFinder {
  _FlowySvgFinder(this.svg);

  final FlowySvgData svg;

  @override
  String get description => 'flowy_svg "$svg"';

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    return widget is FlowySvg && widget.svg == svg;
  }
}
