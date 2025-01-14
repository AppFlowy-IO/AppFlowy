import 'package:appflowy/ai/service/ai_client.dart';
import 'package:appflowy/ai/service/appflowy_ai_service.dart';
import 'package:appflowy/ai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/widgets/ask_ai_action_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../util.dart';

const _aiResponse = 'UPDATED:';

class _MockAIRepository extends Mock implements AIRepository {
  @override
  Future<void> streamCompletion({
    String? objectId,
    required String text,
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    await onStart();
    final lines = text.split('\n\n');
    for (var i = 0; i < lines.length; i++) {
      await onProcess('$_aiResponse ${lines[i]}\n\n');
    }
    await onEnd();
  }
}

class _MockAIRepositoryLess extends Mock implements AIRepository {
  @override
  Future<void> streamCompletion({
    String? objectId,
    required String text,
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    await onStart();
    // only return 1 line.
    await onProcess('Hello World');
    await onEnd();
  }
}

class _MockAIRepositoryMore extends Mock implements AIRepository {
  @override
  Future<void> streamCompletion({
    String? objectId,
    required String text,
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    await onStart();
    // return 10 lines
    for (var i = 0; i < 10; i++) {
      await onProcess('Hello World\n\n');
    }
    await onEnd();
  }
}

class _MockErrorRepository extends Mock implements AIRepository {
  @override
  Future<void> streamCompletion({
    String? objectId,
    required String text,
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    await onStart();
    onError(
      const AIError(
        message: 'Error',
        code: AIErrorCode.aiResponseLimitExceeded,
      ),
    );
  }
}

void main() {
  group('AskAIActionBloc: ', () {
    const text1 = '1. Select text to style using the toolbar menu.';
    const text2 = '2. Discover more styling options in Aa.';
    const text3 =
        '3. AppFlowy empowers you to beautifully and effortlessly style your content.';

    blocTest<AskAIActionBloc, AskAIState>(
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
        final editorState = EditorState(document: document);
        editorState.selection = Selection(
          start: Position(path: [0]),
          end: Position(path: [2], offset: text3.length),
        );

        final node = askAINode(
          action: AskAIAction.makeItLonger,
          content: [text1, text2, text3].join('\n'),
        );
        return AskAIActionBloc(
          objectId: "",
          node: node,
          editorState: editorState,
          action: AskAIAction.makeItLonger,
          enableLogging: false,
        );
      },
      act: (bloc) {
        bloc.add(AskAIEvent.initial(Future.value(_MockAIRepository())));
        bloc.add(const AskAIEvent.rewrite());
      },
      expect: () => [
        isA<AskAIState>()
            .having((s) => s.loading, 'loading', true)
            .having((s) => s.result, 'result', isEmpty),
        isA<AskAIState>()
            .having((s) => s.loading, 'loading', false)
            .having((s) => s.result, 'result', isNotEmpty)
            .having((s) => s.result, 'result', contains('UPDATED:')),
        isA<AskAIState>().having((s) => s.loading, 'loading', false),
      ],
    );

    blocTest<AskAIActionBloc, AskAIState>(
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
        final editorState = EditorState(document: document);
        editorState.selection = Selection(
          start: Position(path: [0]),
          end: Position(path: [2], offset: text3.length),
        );

        final node = askAINode(
          action: AskAIAction.makeItLonger,
          content: [text1, text2, text3].join('\n'),
        );
        return AskAIActionBloc(
          objectId: "",
          node: node,
          editorState: editorState,
          action: AskAIAction.makeItLonger,
          enableLogging: false,
        );
      },
      act: (bloc) {
        bloc.add(AskAIEvent.initial(Future.value(_MockErrorRepository())));
        bloc.add(const AskAIEvent.rewrite());
      },
      expect: () => [
        isA<AskAIState>()
            .having((s) => s.loading, 'loading', true)
            .having((s) => s.result, 'result', isEmpty),
        isA<AskAIState>()
            .having((s) => s.requestError, 'requestError', isNotNull)
            .having(
              (s) => s.requestError?.code,
              'requestError.code',
              AIErrorCode.aiResponseLimitExceeded,
            ),
      ],
    );

    test('summary - the result contains the same number of paragraphs',
        () async {
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: text1),
            paragraphNode(text: text2),
            paragraphNode(text: text3),
          ],
        ),
      );
      final editorState = EditorState(document: document);
      editorState.selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text3.length),
      );

      final node = askAINode(
        action: AskAIAction.makeItLonger,
        content: [text1, text2, text3].join('\n\n'),
      );
      final bloc = AskAIActionBloc(
        objectId: "",
        node: node,
        editorState: editorState,
        action: AskAIAction.summarize,
        enableLogging: false,
      );
      bloc.add(AskAIEvent.initial(Future.value(_MockAIRepository())));
      await blocResponseFuture();
      bloc.add(const AskAIEvent.started());
      await blocResponseFuture();
      bloc.add(const AskAIEvent.replace());
      await blocResponseFuture();
      expect(editorState.document.root.children.length, 3);
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

    test('summary - the result less than the original text', () async {
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: text1),
            paragraphNode(text: text2),
            paragraphNode(text: text3),
          ],
        ),
      );
      final editorState = EditorState(document: document);
      editorState.selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text3.length),
      );

      final node = askAINode(
        action: AskAIAction.makeItLonger,
        content: [text1, text2, text3].join('\n'),
      );
      final bloc = AskAIActionBloc(
        objectId: "",
        node: node,
        editorState: editorState,
        action: AskAIAction.summarize,
        enableLogging: false,
      );
      bloc.add(AskAIEvent.initial(Future.value(_MockAIRepositoryLess())));
      await blocResponseFuture();
      bloc.add(const AskAIEvent.started());
      await blocResponseFuture();
      bloc.add(const AskAIEvent.replace());
      await blocResponseFuture();
      expect(editorState.document.root.children.length, 1);
      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        'Hello World',
      );
    });

    test('summary - the result more than the original text', () async {
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: text1),
            paragraphNode(text: text2),
            paragraphNode(text: text3),
          ],
        ),
      );
      final editorState = EditorState(document: document);
      editorState.selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text3.length),
      );

      final node = askAINode(
        action: AskAIAction.makeItLonger,
        content: [text1, text2, text3].join('\n'),
      );
      final bloc = AskAIActionBloc(
        objectId: "",
        node: node,
        editorState: editorState,
        action: AskAIAction.summarize,
        enableLogging: false,
      );
      bloc.add(AskAIEvent.initial(Future.value(_MockAIRepositoryMore())));
      await blocResponseFuture();
      bloc.add(const AskAIEvent.started());
      await blocResponseFuture();
      bloc.add(const AskAIEvent.replace());
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
