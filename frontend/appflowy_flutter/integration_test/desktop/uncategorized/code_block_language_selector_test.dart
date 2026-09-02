import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_block_copy_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_block_language_selector.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
import '../../shared/document_test_operations.dart';
import '../../shared/expectation.dart';
import '../document/document_codeblock_paste_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Code Block Language Selector Test', (tester) async {
    await _initializeCodeBlockTest(tester);

    /// create a new document
    await tester.tapNewPageButton();

    /// tap editor to get focus
    await tester.editor.tapLineOfEditorAt(0);

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
    String language = editorState
        .getNodeAtPath([0])!
        .attributes[CodeBlockKeys.language]
        .toString();
    expect(
      language.toLowerCase(),
      defaultCodeBlockSupportedLanguages.first.toLowerCase(),
    );

    await tester.hoverOnWidget(find.byType(CodeBlockComponentWidget));
    await tester.tapButtonWithName(language);

    await onKey(tester, LogicalKeyboardKey.arrowUp);
    await onKey(tester, LogicalKeyboardKey.enter);

    language = editorState
        .getNodeAtPath([0])!
        .attributes[CodeBlockKeys.language]
        .toString();
    expect(
      language.toLowerCase(),
      defaultCodeBlockSupportedLanguages.last.toLowerCase(),
    );

    await tester.hoverOnWidget(find.byType(CodeBlockComponentWidget));
    await tester.tapButtonWithName(language);
    tester.testTextInput.enterText("rust");
    await onKey(tester, LogicalKeyboardKey.delete);
    await onKey(tester, LogicalKeyboardKey.delete);
    await onKey(tester, LogicalKeyboardKey.arrowDown);
    tester.testTextInput.enterText("st");
    await onKey(tester, LogicalKeyboardKey.arrowDown);
    await onKey(tester, LogicalKeyboardKey.enter);
    language = editorState
        .getNodeAtPath([0])!
        .attributes[CodeBlockKeys.language]
        .toString();
    expect(language.toLowerCase(), 'rust');
  });

  testWidgets('Code blocks wrap independently and persist their state', (
    tester,
  ) async {
    await _initializeCodeBlockTest(tester);

    const documentName = 'Code block wrap test';
    const otherDocumentName = 'Other document';
    final longText = List.filled(500, 'x').join();
    final longLine = 'final value = "$longText";';

    await tester.createNewPageWithNameUnderParent(name: documentName);
    await tester.tapButton(find.byType(AppFlowyEditor));
    await insertCodeBlockInDocument(tester);
    tester.testTextInput.enterText(longLine);
    await tester.pumpAndSettle();

    var editorState = tester.editor.getCurrentEditorState();
    await editorState.apply(
      editorState.transaction
        ..insertNode(
          [1],
          codeBlockNode(delta: Delta()..insert(longLine)),
        ),
    );
    await tester.pumpAndSettle();

    var codeBlocks = find.byType(CodeBlockComponentWidget);
    expect(codeBlocks, findsNWidgets(2));
    expect(
      editorState
          .getNodeAtPath([0])!.attributes[AppFlowyCodeBlockKeys.wrapLines],
      isNull,
    );
    expect(
      tester
          .widget<CodeBlockComponentWidget>(codeBlocks.first)
          .style
          ?.wrapLines,
      isFalse,
    );
    expect(
      find.descendant(
        of: codeBlocks.first,
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    final unwrappedHeight = tester.getSize(codeBlocks.first).height;

    await tester.hoverOnWidget(codeBlocks.first);
    final firstWrapButton = find.descendant(
      of: codeBlocks.first,
      matching: find.byKey(codeBlockWrapButtonKey),
    );
    expect(firstWrapButton, findsOneWidget);
    expect(
      tester.widget<FlowyIconButton>(firstWrapButton).tooltipText,
      LocaleKeys.document_codeBlock_wrapTooltip.tr(),
    );
    expect(
      tester.widget<FlowyIconButton>(firstWrapButton).isSelected,
      isFalse,
    );
    await tester.tapButton(firstWrapButton);
    await tester.pumpAndSettle();

    codeBlocks = find.byType(CodeBlockComponentWidget);
    expect(
      editorState
          .getNodeAtPath([0])!.attributes[AppFlowyCodeBlockKeys.wrapLines],
      isTrue,
    );
    expect(
      editorState
          .getNodeAtPath([1])!.attributes[AppFlowyCodeBlockKeys.wrapLines],
      isNull,
    );
    expect(
      tester
          .widget<CodeBlockComponentWidget>(codeBlocks.first)
          .style
          ?.wrapLines,
      isTrue,
    );
    expect(
      tester.widget<FlowyIconButton>(firstWrapButton).isSelected,
      isTrue,
    );
    expect(
      tester
          .widget<CodeBlockComponentWidget>(codeBlocks.at(1))
          .style
          ?.wrapLines,
      isFalse,
    );
    expect(
      find.descendant(
        of: codeBlocks.first,
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    final wrappedHeight = tester.getSize(codeBlocks.first).height;
    expect(wrappedHeight, greaterThan(unwrappedHeight));

    await tester.createNewPageWithNameUnderParent(name: otherDocumentName);
    await tester.openPage(documentName);
    await tester.pumpAndSettle();

    editorState = tester.editor.getCurrentEditorState();
    codeBlocks = find.byType(CodeBlockComponentWidget);
    expect(codeBlocks, findsNWidgets(2));
    expect(
      editorState
          .getNodeAtPath([0])!.attributes[AppFlowyCodeBlockKeys.wrapLines],
      isTrue,
    );
    expect(
      tester
          .widget<CodeBlockComponentWidget>(codeBlocks.first)
          .style
          ?.wrapLines,
      isTrue,
    );

    await tester.hoverOnWidget(codeBlocks.first);
    await tester.tapButton(
      find.descendant(
        of: codeBlocks.first,
        matching: find.byKey(codeBlockWrapButtonKey),
      ),
    );
    await tester.pumpAndSettle();

    codeBlocks = find.byType(CodeBlockComponentWidget);
    expect(
      editorState
          .getNodeAtPath([0])!.attributes[AppFlowyCodeBlockKeys.wrapLines],
      isFalse,
    );
    expect(
      tester
          .widget<CodeBlockComponentWidget>(codeBlocks.first)
          .style
          ?.wrapLines,
      isFalse,
    );
    expect(
      tester
          .widget<FlowyIconButton>(
            find.descendant(
              of: codeBlocks.first,
              matching: find.byKey(codeBlockWrapButtonKey),
            ),
          )
          .isSelected,
      isFalse,
    );
    expect(tester.getSize(codeBlocks.first).height, lessThan(wrappedHeight));
  });
}

Future<void> _initializeCodeBlockTest(WidgetTester tester) async {
  await tester.initializeAppFlowy();
  await tester.tapAnonymousSignInButton();

  final gettingStartedPage = find.textContaining(
    gettingStarted,
    findRichText: true,
  );
  await tester.pumpUntilFound(
    gettingStartedPage,
    timeout: const Duration(seconds: 30),
  );
  expect(gettingStartedPage, findsAtLeastNWidgets(1));
}

Future<void> onKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.simulateKeyEvent(key);
  await tester.pumpAndSettle();
}
