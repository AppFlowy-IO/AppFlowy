import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/constants.dart';
import '../../shared/util.dart';

const _testDocumentName = 'Test Document';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document title:', () {
    testWidgets('create a new document and edit title', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      expect(title, findsOneWidget);

      // input name
      await tester.enterText(title, _testDocumentName);
      await tester.pumpAndSettle();

      final newTitle = tester.editor.findDocumentTitle(_testDocumentName);
      expect(newTitle, findsOneWidget);

      // press enter to create a new line
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      const firstLine = 'First line of text';
      await tester.ime.insertText(firstLine);
      await tester.pumpAndSettle();

      final firstLineText = find.text(firstLine, findRichText: true);
      expect(firstLineText, findsOneWidget);

      // press cmd/ctrl+left to move the cursor to the start of the line
      if (UniversalPlatform.isMacOS) {
        await tester.simulateKeyEvent(
          LogicalKeyboardKey.arrowLeft,
          isMetaPressed: true,
        );
      } else {
        await tester.simulateKeyEvent(LogicalKeyboardKey.home);
      }
      await tester.pumpAndSettle();

      // press arrow left to delete the first line
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      // check if the title is on focus
      final titleOnFocus = tester.editor.findDocumentTitle(_testDocumentName);
      final titleWidget = tester.widget<TextField>(titleOnFocus);
      expect(titleWidget.focusNode?.hasFocus, isTrue);

      // press the right arrow key to move the cursor to the first line
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowRight);

      // check if the title is not on focus
      expect(titleWidget.focusNode?.hasFocus, isFalse);

      final editorState = tester.editor.getCurrentEditorState();
      expect(editorState.selection, Selection.collapsed(Position(path: [0])));

      // press the backspace key to go to the title
      await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);

      expect(editorState.selection, null);
      expect(titleWidget.focusNode?.hasFocus, isTrue);
    });

    testWidgets('check if the title is saved', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      expect(title, findsOneWidget);

      // input name
      await tester.enterText(title, _testDocumentName);
      await tester.pumpAndSettle();

      if (UniversalPlatform.isLinux) {
        // wait for the name to be saved
        await tester.wait(250);
      }

      // go to the get started page
      await tester.tapButton(
        tester.findPageName(Constants.gettingStartedPageName),
      );

      // go back to the  page
      await tester.tapButton(tester.findPageName(_testDocumentName));

      // check if the title is saved
      final testDocumentTitle = tester.editor.findDocumentTitle(
        _testDocumentName,
      );
      expect(testDocumentTitle, findsOneWidget);
    });

    testWidgets('arrow up from first line moves focus to title',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      await tester.enterText(title, _testDocumentName);
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.ime.insertText('First line of text');
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(LogicalKeyboardKey.home);

      // press the arrow upload
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowUp);

      final titleWidget = tester.widget<TextField>(
        tester.editor.findDocumentTitle(_testDocumentName),
      );
      expect(titleWidget.focusNode?.hasFocus, isTrue);

      final editorState = tester.editor.getCurrentEditorState();
      expect(editorState.selection, null);
    });

    testWidgets(
        'backspace at start of first line moves focus to title and deletes empty paragraph',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      await tester.enterText(title, _testDocumentName);
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

      final editorState = tester.editor.getCurrentEditorState();
      expect(editorState.document.root.children.length, equals(2));

      await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);

      final titleWidget = tester.widget<TextField>(
        tester.editor.findDocumentTitle(_testDocumentName),
      );
      expect(titleWidget.focusNode?.hasFocus, isTrue);

      // at least one empty paragraph node is created
      expect(editorState.document.root.children.length, equals(1));
    });

    testWidgets('arrow right from end of title moves focus to first line',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      await tester.enterText(title, _testDocumentName);
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.ime.insertText('First line of text');

      await tester.tapButton(
        tester.editor.findDocumentTitle(_testDocumentName),
      );
      await tester.simulateKeyEvent(LogicalKeyboardKey.end);
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowRight);

      final editorState = tester.editor.getCurrentEditorState();
      expect(
        editorState.selection,
        Selection.collapsed(
          Position(path: [0]),
        ),
      );
    });

    testWidgets('change the title via sidebar, check the title is updated',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      expect(title, findsOneWidget);

      await tester.hoverOnPageName(
        '',
        onHover: () async {
          await tester.renamePage(_testDocumentName);
          await tester.pumpAndSettle();
        },
      );
      await tester.pumpAndSettle();

      final newTitle = tester.editor.findDocumentTitle(_testDocumentName);
      expect(newTitle, findsOneWidget);
    });

    testWidgets('execute undo and redo in title', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      await tester.enterText(title, _testDocumentName);
      // press a random key to make the undo stack not empty
      await tester.simulateKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle();

      // undo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      // wait for the undo to be applied
      await tester.pumpAndSettle(Durations.long1);

      // expect the title is empty
      expect(
        tester
            .widget<TextField>(
              tester.editor.findDocumentTitle(''),
            )
            .controller
            ?.text,
        '',
      );

      // redo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
        isShiftPressed: true,
      );

      await tester.pumpAndSettle(Durations.short1);

      if (UniversalPlatform.isMacOS) {
        expect(
          tester
              .widget<TextField>(
                tester.editor.findDocumentTitle(_testDocumentName),
              )
              .controller
              ?.text,
          _testDocumentName,
        );
      }
    });

    testWidgets('escape key should exit the editing mode', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      await tester.enterText(title, _testDocumentName);
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              tester.editor.findDocumentTitle(_testDocumentName),
            )
            .focusNode
            ?.hasFocus,
        isFalse,
      );
    });

    testWidgets('press arrow down key in title, check if the cursor flashes',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      await tester.enterText(title, _testDocumentName);
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      const inputText = 'Hello World';
      await tester.ime.insertText(inputText);

      await tester.tapButton(
        tester.editor.findDocumentTitle(_testDocumentName),
      );
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowDown);
      final editorState = tester.editor.getCurrentEditorState();
      expect(
        editorState.selection,
        Selection.collapsed(
          Position(path: [0], offset: inputText.length),
        ),
      );
    });

    testWidgets(
        'hover on the cover title, check if the add icon & add cover button are shown',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      final title = tester.editor.findDocumentTitle('');
      await tester.hoverOnWidget(
        title,
        onHover: () async {
          expect(find.byType(DocumentCoverWidget), findsOneWidget);
        },
      );

      await tester.pumpAndSettle();
    });
  });
}
