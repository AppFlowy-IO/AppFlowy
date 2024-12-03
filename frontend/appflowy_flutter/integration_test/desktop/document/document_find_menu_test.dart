import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String generateRandomString(int len) {
    final r = Random();
    return String.fromCharCodes(
      List.generate(len, (index) => r.nextInt(33) + 89),
    );
  }

  testWidgets(
    'document find menu test',
    (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // tap editor to get focus
      await tester.tapButton(find.byType(AppFlowyEditor));

      // set clipboard data
      final data = [
        "123456\n",
        ...List.generate(100, (_) => "${generateRandomString(50)}\n"),
        "1234567\n",
        ...List.generate(100, (_) => "${generateRandomString(50)}\n"),
        "12345678\n",
        ...List.generate(100, (_) => "${generateRandomString(50)}\n"),
      ].join();
      await getIt<ClipboardService>().setData(
        ClipboardServiceData(
          plainText: data,
        ),
      );

      // paste
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed:
            UniversalPlatform.isLinux || UniversalPlatform.isWindows,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // go back to beginning of document
      // FIXME: Cannot run Ctrl+F unless selection is on screen
      await tester.editor
          .updateSelection(Selection.collapsed(Position(path: [0])));
      await tester.pumpAndSettle();

      expect(find.byType(FindAndReplaceMenuWidget), findsNothing);

      // press cmd/ctrl+F to display the find menu
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyF,
        isControlPressed:
            UniversalPlatform.isLinux || UniversalPlatform.isWindows,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(FindAndReplaceMenuWidget), findsOneWidget);

      final textField = find.descendant(
        of: find.byType(FindAndReplaceMenuWidget),
        matching: find.byType(TextField),
      );

      await tester.enterText(
        textField,
        "123456",
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.text("123456", findRichText: true),
        ),
        findsOneWidget,
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.text("1234567", findRichText: true),
        ),
        findsOneWidget,
      );

      await tester.showKeyboard(textField);
      await tester.idle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.text("12345678", findRichText: true),
        ),
        findsOneWidget,
      );

      // tap next button, go back to beginning of document
      await tester.tapButton(
        find.descendant(
          of: find.byType(FindMenu),
          matching: find.byFlowySvg(FlowySvgs.arrow_down_s),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.text("123456", findRichText: true),
        ),
        findsOneWidget,
      );
    },
  );
}
