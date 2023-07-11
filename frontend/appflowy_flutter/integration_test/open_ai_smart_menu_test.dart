import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/openai_client.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'util/mock/mock_openai_repository.dart';
import 'util/util.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_widget.dart';
import 'package:appflowy/startup/startup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const service = TestWorkspaceService(TestWorkspace.aiWorkSpace);

  group('integration tests for open-ai smart menu', () {
    setUpAll(() async => await service.setUpAll());
    setUp(() async => await service.setUp());

    testWidgets('testing selection on open-ai smart menu replace',
        (tester) async {
      final appFlowyEditor = await setUpOpenAITesting(tester);
      final editorState = appFlowyEditor.editorState;

      editorState.service.selectionService.updateSelection(
        Selection(
          start: Position(path: [1], offset: 4),
          end: Position(path: [1], offset: 10),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ToolbarWidget), findsAtLeastNWidgets(1));

      await tester.tap(find.byTooltip('AI Assistants'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.text('Summarize'));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byType(FlowyRichTextButton, skipOffstage: false).first);
      await tester.pumpAndSettle();

      expect(
        editorState.service.selectionService.currentSelection.value,
        Selection(
          start: Position(path: [1], offset: 4),
          end: Position(path: [1], offset: 84),
        ),
      );
    });
    testWidgets('testing selection on open-ai smart menu insert',
        (tester) async {
      final appFlowyEditor = await setUpOpenAITesting(tester);
      final editorState = appFlowyEditor.editorState;

      editorState.service.selectionService.updateSelection(
        Selection(
          start: Position(path: [1], offset: 0),
          end: Position(path: [1], offset: 5),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(ToolbarWidget), findsAtLeastNWidgets(1));

      await tester.tap(find.byTooltip('AI Assistants'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.text('Summarize'));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byType(FlowyRichTextButton, skipOffstage: false).at(1));
      await tester.pumpAndSettle();

      expect(
        editorState.service.selectionService.currentSelection.value,
        Selection(
          start: Position(path: [2], offset: 0),
          end: Position(path: [3], offset: 0),
        ),
      );
    });
  });
}

Future<AppFlowyEditor> setUpOpenAITesting(WidgetTester tester) async {
  await tester.initializeAppFlowy();
  await mockOpenAIRepository();

  await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await simulateKeyDownEvent(LogicalKeyboardKey.backslash);
  await tester.pumpAndSettle();

  final Finder editor = find.byType(AppFlowyEditor);
  await tester.tap(editor);
  await tester.pumpAndSettle();
  return (tester.state(editor).widget as AppFlowyEditor);
}

Future<void> mockOpenAIRepository() async {
  await getIt.unregister<OpenAIRepository>();
  getIt.registerFactoryAsync<OpenAIRepository>(
    () => Future.value(
      MockOpenAIRepository(),
    ),
  );
  return;
}
