import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/base.dart';
import 'util/common_operations.dart';

const _readmeName = 'Read me';
const _documentName = 'Document';
const _calendarName = 'Calendar';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tabs', () {
    testWidgets('Open AppFlowy and open/navigate multiple tabs',
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

      await tester.createNewPageWithName(ViewLayoutPB.Calendar, _calendarName);
      await tester.createNewPageWithName(ViewLayoutPB.Document, _documentName);

      // Navigate current view to "Read me" document again
      await tester.tapButtonWithName(_readmeName);

      /// Open second menu item in a new tab
      await tester.openAppInNewTab(_calendarName);

      /// Open third menu item in a new tab
      await tester.openAppInNewTab(_documentName);

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(TabBar),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byType(TabBar),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(3),
      );

      /// Navigate to the first tab
      await tester.tap(
        find.descendant(
          of: find.byType(FlowyTab),
          matching: find.text(_readmeName),
        ),
      );
    });
  });
}
