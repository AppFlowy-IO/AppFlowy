import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('inline math equation in document', () {
    testWidgets('insert an inline math equation', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'math equation',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a inline page
      const formula = 'E = MC ^ 2';
      await tester.ime.insertText(formula);
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: formula.length),
      );

      // tap the more options button
      final moreOptionButton = find.findFlowyTooltip(
        LocaleKeys.document_toolbar_moreOptions.tr(),
      );
      await tester.tapButton(moreOptionButton);

      // tap the inline math equation button
      final inlineMathEquationButton = find.text(
        LocaleKeys.editor_mathEquationShortForm.tr(),
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

    testWidgets('remove the inline math equation format', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'math equation',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a inline page
      const formula = 'E = MC ^ 2';
      await tester.ime.insertText(formula);
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: formula.length),
      );

      // tap the more options button
      final moreOptionButton = find.findFlowyTooltip(
        LocaleKeys.document_toolbar_moreOptions.tr(),
      );
      await tester.tapButton(moreOptionButton);

      // tap the inline math equation button
      final inlineMathEquationButton =
          find.byFlowySvg(FlowySvgs.type_formula_m);
      await tester.tapButton(inlineMathEquationButton);

      // expect to see the math equation block
      var inlineMathEquation = find.byType(InlineMathEquation);
      expect(inlineMathEquation, findsOneWidget);

      // highlight the math equation block
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: 1),
      );

      await tester.tapButton(moreOptionButton);
      // expect to the see the inline math equation button is highlighted
      expect(
        tester.widget<FlowySvg>(inlineMathEquationButton).color != null,
        isTrue,
      );

      // cancel the format
      await tester.tapButton(inlineMathEquationButton);

      // expect to see the math equation block is removed
      inlineMathEquation = find.byType(InlineMathEquation);
      expect(inlineMathEquation, findsNothing);

      tester.expectToSeeText(formula);
    });

    testWidgets('insert a inline math equation and type something after it',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'math equation',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a inline page
      const formula = 'E = MC ^ 2';
      await tester.ime.insertText(formula);
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: formula.length),
      );

      // tap the more options button
      final moreOptionButton = find.findFlowyTooltip(
        LocaleKeys.document_toolbar_moreOptions.tr(),
      );
      await tester.tapButton(moreOptionButton);

      // tap the inline math equation button
      final inlineMathEquationButton =
          find.byFlowySvg(FlowySvgs.type_formula_m);
      await tester.tapButton(inlineMathEquationButton);

      // expect to see the math equation block
      final inlineMathEquation = find.byType(InlineMathEquation);
      expect(inlineMathEquation, findsOneWidget);

      await tester.editor.tapLineOfEditorAt(0);
      const text = 'Hello World';
      await tester.ime.insertText(text);

      final inlineText = find.textContaining(text, findRichText: true);
      expect(inlineText, findsOneWidget);

      // the text should be in the same line with the math equation
      final inlineMathEquationPosition = tester.getRect(inlineMathEquation);
      final textPosition = tester.getRect(inlineText);
      // allow 5px difference
      expect(
        (textPosition.top - inlineMathEquationPosition.top).abs(),
        lessThan(5),
      );
      expect(
        (textPosition.bottom - inlineMathEquationPosition.bottom).abs(),
        lessThan(5),
      );
    });

    testWidgets('insert inline math equation by shortcut', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'insert inline math equation by shortcut',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a inline page
      const formula = 'E = MC ^ 2';
      await tester.ime.insertText(formula);
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: formula.length),
      );

      // mock key event
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyE,
        isShiftPressed: true,
        isControlPressed: true,
      );

      // expect to see the math equation block
      final inlineMathEquation = find.byType(InlineMathEquation);
      expect(inlineMathEquation, findsOneWidget);

      await tester.editor.tapLineOfEditorAt(0);
      const text = 'Hello World';
      await tester.ime.insertText(text);

      final inlineText = find.textContaining(text, findRichText: true);
      expect(inlineText, findsOneWidget);

      // the text should be in the same line with the math equation
      final inlineMathEquationPosition = tester.getRect(inlineMathEquation);
      final textPosition = tester.getRect(inlineText);
      // allow 5px difference
      expect(
        (textPosition.top - inlineMathEquationPosition.top).abs(),
        lessThan(5),
      );
      expect(
        (textPosition.bottom - inlineMathEquationPosition.bottom).abs(),
        lessThan(5),
      );
    });
  });
}
