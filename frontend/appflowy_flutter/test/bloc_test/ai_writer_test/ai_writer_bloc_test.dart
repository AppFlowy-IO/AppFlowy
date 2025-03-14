import 'dart:async';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/operations/ai_writer_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/operations/ai_writer_entities.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../util.dart';

const _aiResponse = 'UPDATED:';

class _MockCompletionStream extends Mock implements CompletionStream {}

class _MockAIRepository extends Mock implements AppFlowyAIService {
  @override
  Future<(String, CompletionStream)?> streamCompletion({
    String? objectId,
    required String text,
    PredefinedFormat? format,
    List<String> sourceIds = const [],
    List<AiWriterRecord> history = const [],
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    final stream = _MockCompletionStream();
    unawaited(
      Future(() async {
        await onStart();
        final lines = text.split('\n');
        for (final line in lines) {
          if (line.isNotEmpty) {
            await onProcess('$_aiResponse $line\n\n');
          }
        }
        await onEnd();
      }),
    );
    return ('mock_id', stream);
  }
}

class _MockAIRepositoryLess extends Mock implements AppFlowyAIService {
  @override
  Future<(String, CompletionStream)?> streamCompletion({
    String? objectId,
    required String text,
    PredefinedFormat? format,
    List<String> sourceIds = const [],
    List<AiWriterRecord> history = const [],
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    final stream = _MockCompletionStream();
    unawaited(
      Future(() async {
        await onStart();
        // only return 1 line.
        await onProcess('Hello World');
        await onEnd();
      }),
    );
    return ('mock_id', stream);
  }
}

class _MockAIRepositoryMore extends Mock implements AppFlowyAIService {
  @override
  Future<(String, CompletionStream)?> streamCompletion({
    String? objectId,
    required String text,
    PredefinedFormat? format,
    List<String> sourceIds = const [],
    List<AiWriterRecord> history = const [],
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    final stream = _MockCompletionStream();
    unawaited(
      Future(() async {
        await onStart();
        // return 10 lines
        for (var i = 0; i < 10; i++) {
          await onProcess('Hello World\n\n');
        }
        await onEnd();
      }),
    );
    return ('mock_id', stream);
  }
}

class _MockErrorRepository extends Mock implements AppFlowyAIService {
  @override
  Future<(String, CompletionStream)?> streamCompletion({
    String? objectId,
    required String text,
    PredefinedFormat? format,
    List<String> sourceIds = const [],
    List<AiWriterRecord> history = const [],
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    final stream = _MockCompletionStream();
    unawaited(
      Future(() async {
        await onStart();
        onError(
          const AIError(
            message: 'Error',
            code: AIErrorCode.aiResponseLimitExceeded,
          ),
        );
      }),
    );
    return ('mock_id', stream);
  }
}

void main() {
  group('AIWriterCubit:', () {
    const text1 = '1. Select text to style using the toolbar menu.';
    const text2 = '2. Discover more styling options in Aa.';
    const text3 =
        '3. AppFlowy empowers you to beautifully and effortlessly style your content.';

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    blocTest<AiWriterCubit, AiWriterState>(
      'send request before the bloc is initialized',
      build: () {
        final document = Document(
          root: pageNode(
            children: [
              paragraphNode(text: text1),
              paragraphNode(text: text2),
              paragraphNode(text: text3),
            ],
          ),
        );
        final selection = Selection(
          start: Position(path: [0]),
          end: Position(path: [2], offset: text3.length),
        );
        final editorState = EditorState(document: document)
          ..selection = selection;
        final command = AiWriterCommand.explain;
        final node = aiWriterNode(
          command: command,
          selection: selection,
        );
        return AiWriterCubit(
          documentId: '',
          getAiWriterNode: () => node,
          editorState: editorState,
          initialCommand: command,
          aiService: _MockAIRepository(),
        );
      },
      act: (bloc) => bloc.init(),
      expect: () => [
        isA<GeneratingAiWriterState>()
            .having((s) => s.markdownText, 'result', isEmpty),
        isA<GeneratingAiWriterState>()
            .having((s) => s.markdownText, 'result', isNotEmpty)
            .having((s) => s.markdownText, 'result', contains('UPDATED:')),
        isA<GeneratingAiWriterState>()
            .having((s) => s.markdownText, 'result', isNotEmpty)
            .having((s) => s.markdownText, 'result', contains('UPDATED:')),
        isA<GeneratingAiWriterState>()
            .having((s) => s.markdownText, 'result', isNotEmpty)
            .having((s) => s.markdownText, 'result', contains('UPDATED:')),
        isA<ReadyAiWriterState>()
            .having((s) => s.markdownText, 'result', isNotEmpty)
            .having((s) => s.markdownText, 'result', contains('UPDATED:')),
      ],
    );

    blocTest<AiWriterCubit, AiWriterState>(
      'exceed the ai response limit',
      build: () {
        const text1 = '1. Select text to style using the toolbar menu.';
        const text2 = '2. Discover more styling options in Aa.';
        const text3 =
            '3. AppFlowy empowers you to beautifully and effortlessly style your content.';
        final document = Document(
          root: pageNode(
            children: [
              paragraphNode(text: text1),
              paragraphNode(text: text2),
              paragraphNode(text: text3),
            ],
          ),
        );
        final selection = Selection(
          start: Position(path: [0]),
          end: Position(path: [2], offset: text3.length),
        );
        final editorState = EditorState(document: document)
          ..selection = selection;
        final node = aiWriterNode(
          command: AiWriterCommand.explain,
          selection: selection,
        );
        return AiWriterCubit(
          documentId: '',
          getAiWriterNode: () => node,
          editorState: editorState,
          initialCommand: AiWriterCommand.explain,
          aiService: _MockErrorRepository(),
        );
      },
      act: (bloc) => bloc.init(),
      expect: () => [
        isA<GeneratingAiWriterState>()
            .having((s) => s.markdownText, 'result', isEmpty),
        isA<ErrorAiWriterState>().having(
          (s) => s.error.code,
          'error code',
          AIErrorCode.aiResponseLimitExceeded,
        ),
      ],
    );

    test('improve writing - the result contains the same number of paragraphs',
        () async {
      final selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text3.length),
      );
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: text1),
            paragraphNode(text: text2),
            paragraphNode(text: text3),
            aiWriterNode(
              command: AiWriterCommand.improveWriting,
              selection: selection,
            ),
          ],
        ),
      );
      final editorState = EditorState(document: document)
        ..selection = selection;
      final aiNode = editorState.getNodeAtPath([3])!;
      final bloc = AiWriterCubit(
        documentId: '',
        getAiWriterNode: () => aiNode,
        editorState: editorState,
        initialCommand: AiWriterCommand.improveWriting,
        aiService: _MockAIRepository(),
      );
      bloc.init();
      await blocResponseFuture();
      bloc.runResponseAction(SuggestionAction.accept);
      await blocResponseFuture();
      expect(
        editorState.document.root.children.length,
        3,
      );
      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        '$_aiResponse $text1',
      );
      expect(
        editorState.getNodeAtPath([1])!.delta!.toPlainText(),
        '$_aiResponse $text2',
      );
      expect(
        editorState.getNodeAtPath([2])!.delta!.toPlainText(),
        '$_aiResponse $text3',
      );
    });

    test('improve writing - discard', () async {
      final selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text3.length),
      );
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: text1),
            paragraphNode(text: text2),
            paragraphNode(text: text3),
            aiWriterNode(
              command: AiWriterCommand.improveWriting,
              selection: selection,
            ),
          ],
        ),
      );
      final editorState = EditorState(document: document)
        ..selection = selection;
      final aiNode = editorState.getNodeAtPath([3])!;
      final bloc = AiWriterCubit(
        documentId: '',
        getAiWriterNode: () => aiNode,
        editorState: editorState,
        initialCommand: AiWriterCommand.improveWriting,
        aiService: _MockAIRepository(),
      );
      bloc.init();
      await blocResponseFuture();
      bloc.runResponseAction(SuggestionAction.discard);
      await blocResponseFuture();
      expect(
        editorState.document.root.children.length,
        3,
      );
      expect(editorState.getNodeAtPath([0])!.delta!.toPlainText(), text1);
      expect(editorState.getNodeAtPath([1])!.delta!.toPlainText(), text2);
      expect(editorState.getNodeAtPath([2])!.delta!.toPlainText(), text3);
    });

    test('improve writing - the result less than the original text', () async {
      final selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text3.length),
      );
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: text1),
            paragraphNode(text: text2),
            paragraphNode(text: text3),
            aiWriterNode(
              command: AiWriterCommand.improveWriting,
              selection: selection,
            ),
          ],
        ),
      );
      final editorState = EditorState(document: document)
        ..selection = selection;
      final aiNode = editorState.getNodeAtPath([3])!;
      final bloc = AiWriterCubit(
        documentId: '',
        getAiWriterNode: () => aiNode,
        editorState: editorState,
        initialCommand: AiWriterCommand.improveWriting,
        aiService: _MockAIRepositoryLess(),
      );
      bloc.init();
      await blocResponseFuture();
      bloc.runResponseAction(SuggestionAction.accept);
      await blocResponseFuture();
      expect(editorState.document.root.children.length, 1);
      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        'Hello World',
      );
    });

    test('improve writing - the result more than the original text', () async {
      final selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text3.length),
      );
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: text1),
            paragraphNode(text: text2),
            paragraphNode(text: text3),
            aiWriterNode(
              command: AiWriterCommand.improveWriting,
              selection: selection,
            ),
          ],
        ),
      );
      final editorState = EditorState(document: document)
        ..selection = selection;
      final aiNode = editorState.getNodeAtPath([3])!;
      final bloc = AiWriterCubit(
        documentId: '',
        getAiWriterNode: () => aiNode,
        editorState: editorState,
        initialCommand: AiWriterCommand.improveWriting,
        aiService: _MockAIRepositoryMore(),
      );
      bloc.init();
      await blocResponseFuture();
      bloc.runResponseAction(SuggestionAction.accept);
      await blocResponseFuture();
      expect(editorState.document.root.children.length, 10);
      for (var i = 0; i < 10; i++) {
        expect(
          editorState.getNodeAtPath([i])!.delta!.toPlainText(),
          'Hello World',
        );
      }
    });
  });
}
