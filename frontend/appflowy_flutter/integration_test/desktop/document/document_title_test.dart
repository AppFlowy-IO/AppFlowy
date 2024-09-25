import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document title: ', () {
    // 1. create a new document
    // 2. edit title
    // 3. press enter to create a new line
    // 4. insert text
    testWidgets('create a new document and edit title', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      const name = 'Hello World';
      final title = tester.editor.findDocumentTitle('');
      expect(title, findsOneWidget);

      // input name
      await tester.enterText(title, name);
      await tester.pumpAndSettle();

      final newTitle = tester.editor.findDocumentTitle(name);
      expect(newTitle, findsOneWidget);

      // press enter to create a new line
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      const firstLine = 'This is the first line';
      await tester.ime.insertText(firstLine);
      await tester.pumpAndSettle();

      final firstLineText = find.text(firstLine, findRichText: true);
      expect(firstLineText, findsOneWidget);

      // press cmd/ctrl+left to move the cursor to the start of the line
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.arrowLeft,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // press arrow left to delete the first line
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      // check if the title is on focus
      final titleOnFocus = tester.editor.findDocumentTitle(name);
      final titleWidget = tester.widget<TextField>(titleOnFocus);
      expect(titleWidget.focusNode?.hasFocus, isTrue);

      // press the right arrow key to move the cursor to the first line
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // check if the title is not on focus
      expect(titleWidget.focusNode?.hasFocus, isFalse);

      final editorState = tester.editor.getCurrentEditorState();
      expect(editorState.selection, Selection.collapsed(Position(path: [0])));

      // press the backspace key to go to the title
      await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(editorState.selection, null);
      expect(titleWidget.focusNode?.hasFocus, isTrue);
    });
  });
}
