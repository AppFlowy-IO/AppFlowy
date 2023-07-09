import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/ime.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('inline math equation in document', () {
    testWidgets('insert an inline math equation', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new document
      await tester.createNewPageWithName(
        ViewLayoutPB.Document,
        LocaleKeys.document_plugins_createInlineMathEquation.tr(),
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a inline page
      const formula = 'E = MC ^ 2';
      await tester.ime.insertText(formula);
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: formula.length),
      );

      // tap the inline math equation button
      final inlineMathEquationButton = find.byTooltip(
        LocaleKeys.document_plugins_createInlineMathEquation.tr(),
      );
      await tester.tapButton(inlineMathEquationButton);

      // expect to see the math equation block
      final inlineMathEquation = find.byType(InlineMathEquation);
      expect(inlineMathEquation, findsOneWidget);

      // tap it and update the content
      await tester.tapButton(inlineMathEquation);
      final textFormField = find.descendant(
        of: find.byType(MathInputTextField),
        matching: find.byType(TextFormField),
      );
      const newFormula = 'E = MC ^ 3';
      await tester.enterText(textFormField, newFormula);
      await tester.tapButton(
        find.descendant(
          of: find.byType(MathInputTextField),
          matching: find.byType(FlowyButton),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}
