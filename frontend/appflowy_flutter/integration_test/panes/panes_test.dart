import 'package:appflowy/workspace/presentation/home/panes/flowy_pane.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

const _documentName = 'First Doc';
const _documentTwoName = 'Second Doc';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Core pane tests', () {
    testWidgets('Open AppFlowy and open/navigate/close panes', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(find.byType(FlowyPane), findsOneWidget);

      await tester.createNewPageWithNameUnderParent(
        name: _documentName,
        layout: ViewLayoutPB.Document,
      );

      await tester.createNewPageWithNameUnderParent(
        name: _documentTwoName,
        layout: ViewLayoutPB.Document,
      );

      await tester.openViewInNewPane(
        gettingStarted,
        ViewLayoutPB.Document,
        Axis.horizontal,
      );

      expect(find.byType(FlowyPane), findsNWidgets(2));

      await tester.openViewInNewPane(_documentName, ViewLayoutPB.Document);

      expect(find.byType(FlowyPane), findsNWidgets(3));

      await tester.tap(
        find.descendant(
          of: find.byType(FlowyPane),
          matching: find.text(gettingStarted),
        ),
      );

      await tester.closePaneWithVisibleCloseButton();

      expect(find.byType(FlowyPane), findsNWidgets(2));
    });

    testWidgets('user can open atmost 4 panes', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(find.byType(FlowyPane), findsOneWidget);

      for (int i = 0; i < 5; i++) {
        await tester.openViewInNewPane(
          gettingStarted,
          ViewLayoutPB.Document,
          Axis.horizontal,
        );
      }

      expect(find.byType(FlowyPane), findsNWidgets(4));
    });
  });
}
