import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/text_completion.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

class AppFlowyAIService implements AIRepository {
  @override
  Future<FlowyResult<List<String>, AIError>> generateImage({
    required String prompt,
    int n = 1,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> getStreamedCompletions({
    required String prompt,
    required Future<void> Function() onStart,
    required Future<void> Function(TextCompletionResponse response) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
    String? suffix,
    int maxTokens = 2048,
    double temperature = 0.3,
    bool useAction = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CompletionStream> streamCompletion({
    required String text,
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    final stream = CompletionStream(
      onStart,
      onProcess,
      onEnd,
      onError,
    );
    final payload = CompleteTextPB(
      text: text,
      completionType: completionType,
      streamPort: fixnum.Int64(stream.nativePort),
    );

    // ignore: unawaited_futures
    AIEventCompleteText(payload).send();
    return stream;
  }
}

CompletionTypePB completionTypeFromInt(SmartEditAction action) {
  switch (action) {
    case SmartEditAction.summarize:
      return CompletionTypePB.MakeShorter;
    case SmartEditAction.fixSpelling:
      return CompletionTypePB.SpellingAndGrammar;
    case SmartEditAction.improveWriting:
      return CompletionTypePB.ImproveWriting;
    case SmartEditAction.makeItLonger:
      return CompletionTypePB.MakeLonger;
  }
}

class CompletionStream {
  CompletionStream(
    Future<void> Function() onStart,
    Future<void> Function(String text) onProcess,
    Future<void> Function() onEnd,
    void Function(AIError error) onError,
  ) {
    _port.handler = _controller.add;
    _subscription = _controller.stream.listen(
      (event) async {
        if (event == "AI_RESPONSE_LIMIT") {
          onError(
            AIError(
              message: LocaleKeys.sideBar_aiResponseLimit.tr(),
              code: AIErrorCode.aiResponseLimitExceeded,
            ),
          );
        }

        if (event.startsWith("start:")) {
          await onStart();
        }

        if (event.startsWith("data:")) {
          await onProcess(event.substring(5));
        }

        if (event.startsWith("finish:")) {
          await onEnd();
        }

        if (event.startsWith("error:")) {
          onError(AIError(message: event.substring(6)));
        }
      },
    );
  }

  final RawReceivePort _port = RawReceivePort();
  final StreamController<String> _controller = StreamController.broadcast();
  late StreamSubscription<String> _subscription;
  int get nativePort => _port.sendPort.nativePort;

  Future<void> dispose() async {
    await _controller.close();
    await _subscription.cancel();
    _port.close();
  }

  StreamSubscription<String> listen(
    void Function(String event)? onData,
  ) {
    return _controller.stream.listen(onData);
  }
}
