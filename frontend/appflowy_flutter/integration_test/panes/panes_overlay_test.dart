import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/panes/flowy_pane.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

const _documentName = 'First Doc';
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Panes overlay/read-only views test', () {
    testWidgets(
        'Opening a new pane of same type marks existing pane as readonly, test assumes read only views are unmodifiable',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(find.byType(FlowyPane), findsOneWidget);

      for (int i = 0; i < 2; i++) {
        await tester.openViewInNewPane(
          gettingStarted,
          ViewLayoutPB.Document,
          Axis.horizontal,
        );
      }

      expect(find.byType(FlowyPane), findsNWidgets(3));
      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(2),
      );
    });

    testWidgets(
        'Switching view on writable pane or closing the writable pane, searches for and converts the first found read only pane to writable',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(find.byType(FlowyPane), findsOneWidget);

      for (int i = 0; i < 2; i++) {
        await tester.openViewInNewPane(
          gettingStarted,
          ViewLayoutPB.Document,
          Axis.horizontal,
        );
      }
      expect(find.byType(FlowyPane), findsNWidgets(3));
      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(2),
      );

      await tester.createNewPageWithNameUnderParent(name: _documentName);
      await tester.tap(find.byType(FlowyPane).first);
      await tester.openPage(_documentName);

      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(1),
      );

      await tester.tap(find.byType(FlowyPane).last);
      await tester.closePaneWithVisibleCloseButton(first: false);

      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(0),
      );
    });

    testWidgets(
        'opening duplicate view in a new tab of different pane is marked as read only, closing the writable view leads to conversion of readonly view to writable view',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(find.byType(FlowyPane), findsOneWidget);

      for (int i = 0; i < 1; i++) {
        await tester.openViewInNewPane(
          gettingStarted,
          ViewLayoutPB.Document,
          Axis.horizontal,
        );
      }
      expect(find.byType(FlowyPane), findsNWidgets(2));
      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(1),
      );

      await tester.tap(find.byType(FlowyPane).first);
      await tester.createNewPageWithNameUnderParent(name: _documentName);

      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(0),
      );

      await tester.openAppInNewTab(gettingStarted, ViewLayoutPB.Document);

      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(1),
      );

      await tester.tap(find.byType(FlowyPane).last);
      await tester.closePaneWithVisibleCloseButton(first: false);

      expect(
        find.textContaining(LocaleKeys.readOnlyViewText.tr()),
        findsNWidgets(0),
      );
    });
  });
}
