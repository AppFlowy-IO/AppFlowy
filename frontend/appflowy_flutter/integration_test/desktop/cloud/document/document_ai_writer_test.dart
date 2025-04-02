import 'package:appflowy/ai/service/ai_entities.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/operations/ai_writer_entities.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/ai_test_op.dart';
import '../../../shared/constants.dart';
import '../../../shared/mock/mock_ai.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Writer:', () {
    testWidgets('the ai writer transaction should only apply in memory',
        (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        aiRepositoryBuilder: () => MockAIRepository(),
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_aiWriter.tr(),
      );
      expect(find.byType(AiWriterBlockComponent), findsOneWidget);

      // switch to another page
      await tester.openPage(Constants.gettingStartedPageName);
      // switch back to the page
      await tester.openPage(pageName);

      // expect the ai writer block is not in the document
      expect(find.byType(AiWriterBlockComponent), findsNothing);
    });

    testWidgets('Improve writing', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      await tester.editor.tapLineOfEditorAt(0);

      // insert a paragraph
      final text = 'I have an apple';
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText(text);
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0]),
          end: Position(path: [0], offset: text.length),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tapButton(find.byType(ImproveWritingButton));

      final editorState = tester.editor.getCurrentEditorState();
      final document = editorState.document;

      expect(document.root.children.length, 3);
      expect(document.root.children[1].type, ParagraphBlockKeys.type);
      expect(
        document.root.children[1].delta!.toPlainText(),
        'I have an apple and a banana',
      );
    });

    testWidgets('fix grammar', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      await tester.editor.tapLineOfEditorAt(0);

      // insert a paragraph
      final text = 'We didn’t had enough money';
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText(text);
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0]),
          end: Position(path: [0], offset: text.length),
        ),
      );

      await tester.pumpAndSettle();
      await tester.selectAIWriter(AiWriterCommand.fixSpellingAndGrammar);

      final editorState = tester.editor.getCurrentEditorState();
      final document = editorState.document;

      expect(document.root.children.length, 3);
      expect(document.root.children[1].type, ParagraphBlockKeys.type);
      expect(
        document.root.children[1].delta!.toPlainText(),
        'We didn’t have enough money',
      );
    });

    testWidgets('ask ai', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        aiRepositoryBuilder: () => MockAIRepository(
          validator: _CompletionHistoryValidator(),
        ),
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      await tester.editor.tapLineOfEditorAt(0);

      // insert a paragraph
      final text = 'What is TPU?';
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText(text);
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0]),
          end: Position(path: [0], offset: text.length),
        ),
      );

      await tester.pumpAndSettle();
      await tester.selectAIWriter(AiWriterCommand.userQuestion);

      await tester.enterTextInPromptTextField("Explain the concept of TPU");
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      await tester.selectModel("GPT-4o-mini");

      await tester.enterTextInPromptTextField("How about GPU?");
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    });
  });
}

class _CompletionHistoryValidator extends StreamCompletionValidator {
  static const _expectedResponses = {
    1: "What is TPU?",
    3: [
      "What is TPU?",
      "Explain the concept of TPU",
      "TPU is a tensor processing unit that is designed to accelerate machine",
    ],
    5: [
      "What is TPU?",
      "Explain the concept of TPU",
      "TPU is a tensor processing unit that is designed to accelerate machine",
      "How about GPU?",
      "GPU is a graphics processing unit that is designed to accelerate machine learning tasks.",
    ],
  };

  @override
  bool validate(
    String text,
    String? objectId,
    CompletionTypePB completionType,
    PredefinedFormat? format,
    List<String> sourceIds,
    List<AiWriterRecord> history,
  ) {
    assert(completionType == CompletionTypePB.UserQuestion);
    if (history.isEmpty) return false;

    final expectedMessages = _expectedResponses[history.length];
    if (expectedMessages == null) return false;

    if (expectedMessages is String) {
      _assertMessage(history[0].content, expectedMessages);
      return true;
    } else if (expectedMessages is List<String>) {
      for (var i = 0; i < expectedMessages.length; i++) {
        _assertMessage(history[i].content, expectedMessages[i]);
      }
      return true;
    }

    return false;
  }

  void _assertMessage(String actual, String expected) {
    assert(
      actual.trim() == expected,
      "expected '$expected', but got '${actual.trim()}'",
    );
  }
}
