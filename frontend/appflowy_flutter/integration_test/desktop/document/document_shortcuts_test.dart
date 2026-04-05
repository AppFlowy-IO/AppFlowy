import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document shortcuts:', () {
    testWidgets('custom cut command', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const pageName = 'Test Document Shortcuts';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // focus on the editor
      await tester.tap(find.byType(AppFlowyEditor));

      // mock the data
      final editorState = tester.editor.getCurrentEditorState();
      final transaction = editorState.transaction;
      const text1 = '1. First line';
      const text2 = '2. Second line';
      transaction.insertNodes([
        0,
      ], [
        paragraphNode(text: text1),
        paragraphNode(text: text2),
      ]);
      await editorState.apply(transaction);
      await tester.pumpAndSettle();

      // focus on the end of the first line
      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [0], offset: text1.length),
        ),
      );
      // press the keybinding
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // check the clipboard
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        clipboard?.text,
        equals(text1),
      );

      final node = tester.editor.getNodeAtPath([0]);
      expect(
        node.delta?.toPlainText(),
        equals(text2),
      );

      // select the whole line
      await tester.editor.updateSelection(
        Selection.single(
          path: [0],
          startOffset: 0,
          endOffset: text2.length,
        ),
      );

      // press the keybinding
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // all the text should be deleted
      expect(
        node.delta?.toPlainText(),
        equals(''),
      );

      final clipboard2 = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        clipboard2?.text,
        equals(text2),
      );
    });

    testWidgets(
        'custom copy command - copy whole line when selection is collapsed',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const pageName = 'Test Document Shortcuts';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // focus on the editor
      await tester.tap(find.byType(AppFlowyEditor));

      // mock the data
      final editorState = tester.editor.getCurrentEditorState();
      final transaction = editorState.transaction;
      const text1 = '1. First line';
      transaction.insertNodes([
        0,
      ], [
        paragraphNode(text: text1),
      ]);
      await editorState.apply(transaction);
      await tester.pumpAndSettle();

      // focus on the end of the first line
      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [0], offset: text1.length),
        ),
      );
      // press the keybinding
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyC,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // check the clipboard
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        clipboard?.text,
        equals(text1),
      );
    });

    testWidgets('custom duplicate block command - duplicate current block', (
      tester,
    ) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const pageName = 'Test Duplicate Block Shortcut';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      await tester.tap(find.byType(AppFlowyEditor));

      final editorState = tester.editor.getCurrentEditorState();
      final transaction = editorState.transaction;
      const text1 = 'First block';
      const text2 = 'Second block';
      transaction.insertNodes(
        [0],
        [
          paragraphNode(text: text1),
          paragraphNode(text: text2),
        ],
      );
      await editorState.apply(transaction);
      await tester.pumpAndSettle();

      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [0], offset: text1.length),
        ),
      );

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyD,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(
        tester.editor.getNodeAtPath([0]).delta?.toPlainText(),
        equals(text1),
      );
      expect(
        tester.editor.getNodeAtPath([1]).delta?.toPlainText(),
        equals(text1),
      );
      expect(
        tester.editor.getNodeAtPath([2]).delta?.toPlainText(),
        equals(text2),
      );
    });

    testWidgets(
        'custom duplicate block command - duplicate multi-block selection', (
      tester,
    ) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const pageName = 'Test Duplicate Multi Block Shortcut';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      await tester.tap(find.byType(AppFlowyEditor));

      final editorState = tester.editor.getCurrentEditorState();
      final transaction = editorState.transaction;
      const text1 = 'First block';
      const text2 = 'Second block';
      const text3 = 'Third block';
      transaction.insertNodes(
        [0],
        [
          paragraphNode(text: text1),
          paragraphNode(text: text2),
          paragraphNode(text: text3),
        ],
      );
      await editorState.apply(transaction);
      await tester.pumpAndSettle();

      editorState.selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [1], offset: text2.length),
      );

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyD,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(editorState.document.root.children, hasLength(5));
      expect(
        tester.editor.getNodeAtPath([0]).delta?.toPlainText(),
        equals(text1),
      );
      expect(
        tester.editor.getNodeAtPath([1]).delta?.toPlainText(),
        equals(text2),
      );
      expect(
        tester.editor.getNodeAtPath([2]).delta?.toPlainText(),
        equals(text1),
      );
      expect(
        tester.editor.getNodeAtPath([3]).delta?.toPlainText(),
        equals(text2),
      );
      expect(
        tester.editor.getNodeAtPath([4]).delta?.toPlainText(),
        equals(text3),
      );
    });
  });
}
