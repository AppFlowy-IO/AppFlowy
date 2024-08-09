import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('paste in codeblock', () {
    testWidgets('paste multiple lines in codeblock', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      // mock the clipboard
      const lines = 3;
      final text = List.generate(lines, (index) => 'line $index').join('\n');
      AppFlowyClipboard.mockSetData(AppFlowyClipboardData(text: text));
      ClipboardService.mockSetData(ClipboardServiceData(plainText: text));

      await insertCodeBlockInDocument(tester);

      // paste the text
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      final editorState = tester.editor.getCurrentEditorState();
      expect(editorState.document.root.children.length, 1);
      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        text,
      );
    });
  });
}

/// Inserts an codeBlock in the document
Future<void> insertCodeBlockInDocument(WidgetTester tester) async {
  // open the actions menu and insert the codeBlock
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    LocaleKeys.document_selectionMenu_codeBlock.tr(),
    offset: 150,
  );
  // wait for the codeBlock to be inserted
  await tester.pumpAndSettle();
}
