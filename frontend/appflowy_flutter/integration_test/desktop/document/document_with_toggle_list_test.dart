import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('toggle list in document', () {
    Finder findToggleListIcon({
      required bool isExpanded,
    }) {
      final turns = isExpanded ? 0.25 : 0.0;
      return find.byWidgetPredicate(
        (widget) => widget is AnimatedRotation && widget.turns == turns,
      );
    }

    void expectToggleListOpened() {
      expect(findToggleListIcon(isExpanded: true), findsOneWidget);
      expect(findToggleListIcon(isExpanded: false), findsNothing);
    }

    void expectToggleListClosed() {
      expect(findToggleListIcon(isExpanded: false), findsOneWidget);
      expect(findToggleListIcon(isExpanded: true), findsNothing);
    }

    testWidgets('convert > to toggle list, and click the icon to close it',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a toggle list
      const text = 'This is a toggle list sample';
      await tester.ime.insertText('> $text');

      final editorState = tester.editor.getCurrentEditorState();
      final toggleList = editorState.document.nodeAtPath([0])!;
      expect(
        toggleList.type,
        ToggleListBlockKeys.type,
      );
      expect(
        toggleList.attributes[ToggleListBlockKeys.collapsed],
        false,
      );
      expect(
        toggleList.delta!.toPlainText(),
        text,
      );

      // Simulate pressing enter key to move the cursor to the next line
      await tester.ime.insertCharacter('\n');
      const text2 = 'This is a child node';
      await tester.ime.insertText(text2);
      expect(find.text(text2, findRichText: true), findsOneWidget);

      // Click the toggle list icon to close it
      final toggleListIcon = find.byIcon(Icons.arrow_right);
      await tester.tapButton(toggleListIcon);

      // expect the toggle list to be closed
      expect(find.text(text2, findRichText: true), findsNothing);
    });

    testWidgets('press enter key when the toggle list is closed',
        (tester) async {
      // if the toggle list is closed, press enter key will insert a new toggle list after it
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a toggle list
      const text = 'Hello AppFlowy';
      await tester.ime.insertText('> $text');

      // Click the toggle list icon to close it
      final toggleListIcon = find.byIcon(Icons.arrow_right);
      await tester.tapButton(toggleListIcon);

      // Press the enter key
      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [0], offset: 'Hello '.length),
        ),
      );
      await tester.ime.insertCharacter('\n');

      final editorState = tester.editor.getCurrentEditorState();
      final node0 = editorState.getNodeAtPath([0])!;
      final node1 = editorState.getNodeAtPath([1])!;

      expect(node0.type, ToggleListBlockKeys.type);
      expect(node0.attributes[ToggleListBlockKeys.collapsed], true);
      expect(node0.delta!.toPlainText(), 'Hello ');
      expect(node1.type, ToggleListBlockKeys.type);
      expect(node1.delta!.toPlainText(), 'AppFlowy');
    });

    testWidgets('press enter key when the toggle list is open', (tester) async {
      // if the toggle list is open, press enter key will insert a new paragraph inside it
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a toggle list
      const text = 'Hello AppFlowy';
      await tester.ime.insertText('> $text');

      // Press the enter key
      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [0], offset: 'Hello '.length),
        ),
      );
      await tester.ime.insertCharacter('\n');

      final editorState = tester.editor.getCurrentEditorState();
      final node0 = editorState.getNodeAtPath([0])!;
      final node00 = editorState.getNodeAtPath([0, 0])!;
      final node1 = editorState.getNodeAtPath([1]);

      expect(node0.type, ToggleListBlockKeys.type);
      expect(node0.attributes[ToggleListBlockKeys.collapsed], false);
      expect(node0.delta!.toPlainText(), 'Hello ');
      expect(node00.type, ParagraphBlockKeys.type);
      expect(node00.delta!.toPlainText(), 'AppFlowy');
      expect(node1, isNull);
    });

    testWidgets('clear the format if toggle list if empty', (tester) async {
      // if the toggle list is open, press enter key will insert a new paragraph inside it
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a toggle list
      await tester.ime.insertText('> ');

      // Press the enter key
      // Click the toggle list icon to close it
      final toggleListIcon = find.byIcon(Icons.arrow_right);
      await tester.tapButton(toggleListIcon);

      await tester.editor
          .updateSelection(Selection.collapsed(Position(path: [0])));
      await tester.ime.insertCharacter('\n');

      final editorState = tester.editor.getCurrentEditorState();
      final node0 = editorState.getNodeAtPath([0])!;

      expect(node0.type, ParagraphBlockKeys.type);
    });

    testWidgets('use cmd/ctrl + enter to open/close the toggle list',
        (tester) async {
      // if the toggle list is open, press enter key will insert a new paragraph inside it
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a toggle list
      await tester.ime.insertText('> Hello');

      expectToggleListOpened();

      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [0]),
        ),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.enter,
        isMetaPressed: Platform.isMacOS,
        isControlPressed: Platform.isLinux || Platform.isWindows,
      );

      expectToggleListClosed();

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.enter,
        isMetaPressed: Platform.isMacOS,
        isControlPressed: Platform.isLinux || Platform.isWindows,
      );

      expectToggleListOpened();
    });
  });
}
