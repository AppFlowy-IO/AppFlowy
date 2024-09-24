import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAIRepository extends Mock implements AIRepository {
  @override
  Future<void> streamCompletion({
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
      await onProcess('UPDATED: ${lines[i]}\n\n');
    }
    await onEnd();
  }
}

void main() {
  group('SmartEditorBloc: ', () {
    blocTest<SmartEditBloc, SmartEditState>(
      'send request before the bloc is initialized',
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

        final node = smartEditNode(
          action: SmartEditAction.makeItLonger,
          content: [text1, text2, text3].join('\n'),
        );
        return SmartEditBloc(
          node: node,
          editorState: editorState,
          action: SmartEditAction.makeItLonger,
          enableLogging: false,
        );
      },
      act: (bloc) {
        bloc.add(SmartEditEvent.initial(Future.value(MockAIRepository())));
        bloc.add(const SmartEditEvent.rewrite());
      },
      expect: () => [
        isA<SmartEditState>()
            .having((s) => s.loading, 'loading', true)
            .having((s) => s.result, 'result', isEmpty),
        isA<SmartEditState>()
            .having((s) => s.loading, 'loading', false)
            .having((s) => s.result, 'result', isNotEmpty)
            .having((s) => s.result, 'result', contains('UPDATED:')),
        isA<SmartEditState>().having((s) => s.loading, 'loading', false),
      ],
    );
  });
}


// [
//             _$SmartEditStateImpl:SmartEditState(loading: true, result: , action: SmartEditAction.makeItLonger),
//             _$SmartEditStateImpl:SmartEditState(loading: false, result: UPDATED: 1. Select text to style using the toolbar menu.
//           2. Discover more styling options in Aa.
//           3. AppFlowy empowers you to beautifully and effortlessly style your content.

//           , action: SmartEditAction.makeItLonger),
//             _$SmartEditStateImpl:SmartEditState(loading: false, result:
//           , action: SmartEditAction.makeItLonger)
//           ]