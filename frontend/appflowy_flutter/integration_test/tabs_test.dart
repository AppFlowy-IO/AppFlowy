import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/base.dart';
import 'util/common_operations.dart';
import 'util/expectation.dart';

const _documentName = 'Document';
const _calendarName = 'Calendar';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tabs', () {
    testWidgets('Open AppFlowy and open/navigate/close multiple tabs',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(TabBar),
        ),
        findsNothing,
      );

      await tester.createNewPageWithName(
        name: _calendarName,
        layout: ViewLayoutPB.Calendar,
      );

      await tester.createNewPageWithName(
        name: _documentName,
        layout: ViewLayoutPB.Document,
      );

      // Navigate current view to "Read me" document again
      await tester.tapButtonWithName(gettingStarted);

      /// Open second menu item in a new tab
      await tester.openAppInNewTab(_calendarName, ViewLayoutPB.Calendar);

      /// Open third menu item in a new tab
      await tester.openAppInNewTab(_documentName, ViewLayoutPB.Document);

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(TabBar),
        ),
        findsOneWidget,
      );

      // expect(
      //   find.descendant(
      //     of: find.byType(TabBar),
      //     matching: find.byType(FlowyTab),
      //   ),
      //   findsNWidgets(3),
      // );

      // /// Navigate to the first tab
      // await tester.tap(
      //   find.descendant(
      //     of: find.byType(FlowyTab),
      //     matching: find.text(gettingStarted),
      //   ),
      // );

      // /// Close tab by shortcut
      // await FlowyTestKeyboard.simulateKeyDownEvent(
      //   [
      //     Platform.isMacOS
      //         ? LogicalKeyboardKey.meta
      //         : LogicalKeyboardKey.control,
      //     LogicalKeyboardKey.keyW,
      //   ],
      //   tester: tester,
      // );

      // expect(
      //   find.descendant(
      //     of: find.byType(TabBar),
      //     matching: find.byType(FlowyTab),
      //   ),
      //   findsNWidgets(2),
      // );
    });
  });
}
