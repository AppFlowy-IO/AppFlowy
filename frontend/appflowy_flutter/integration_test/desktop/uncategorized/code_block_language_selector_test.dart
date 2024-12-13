import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_block_language_selector.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
import '../../shared/document_test_operations.dart';
import '../document/document_codeblock_paste_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Code Block Language Selector Test', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    /// create a new document
    await tester.createNewPageWithNameUnderParent();

    /// tap editor to get focus
    await tester.tapButton(find.byType(AppFlowyEditor));

    expect(find.byType(CodeBlockLanguageSelector), findsNothing);
    await insertCodeBlockInDocument(tester);

    ///tap button
    await tester.hoverOnWidget(find.byType(CodeBlockComponentWidget));
    await tester
        .tapButtonWithName(LocaleKeys.document_codeBlock_language_auto.tr());
    expect(find.byType(CodeBlockLanguageSelector), findsOneWidget);

    for (var i = 0; i < 3; ++i) {
      await onKey(tester, LogicalKeyboardKey.arrowDown);
    }
    for (var i = 0; i < 2; ++i) {
      await onKey(tester, LogicalKeyboardKey.arrowUp);
    }

    await onKey(tester, LogicalKeyboardKey.enter);

    final editorState = tester.editor.getCurrentEditorState();
    final language =
        editorState.getNodeAtPath([0])!.attributes['language'].toString();
    expect(
      language.toLowerCase(),
      defaultCodeBlockSupportedLanguages.first.toLowerCase(),
    );

    await tester.hoverOnWidget(find.byType(CodeBlockComponentWidget));
    await tester.tapButtonWithName(language);

    await onKey(tester, LogicalKeyboardKey.arrowUp);
    await onKey(tester, LogicalKeyboardKey.enter);

    expect(
      editorState
          .getNodeAtPath([0])!
          .attributes['language']
          .toString()
          .toLowerCase(),
      defaultCodeBlockSupportedLanguages.last.toLowerCase(),
    );
  });
}

Future<void> onKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.simulateKeyEvent(key);
  await tester.pumpAndSettle();
}
