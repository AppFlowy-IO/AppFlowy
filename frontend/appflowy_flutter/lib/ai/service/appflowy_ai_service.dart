import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

import 'ai_client.dart';
import 'error.dart';
import 'text_completion.dart';

enum AskAIAction {
  summarize,
  fixSpelling,
  improveWriting,
  makeItLonger;

  String get toInstruction => switch (this) {
        summarize => 'Tl;dr',
        fixSpelling => 'Correct this to standard English:',
        improveWriting => 'Rewrite this in your own words:',
        makeItLonger => 'Make this text longer:',
      };

  String prompt(String input) => switch (this) {
        summarize => '$input\n\n$toInstruction',
        _ => "$toInstruction\n\n$input",
      };

  static AskAIAction from(int index) => switch (index) {
        0 => summarize,
        1 => fixSpelling,
        2 => improveWriting,
        3 => makeItLonger,
        _ => fixSpelling
      };

  String get name => switch (this) {
        summarize => LocaleKeys.document_plugins_smartEditSummarize.tr(),
        fixSpelling => LocaleKeys.document_plugins_smartEditFixSpelling.tr(),
        improveWriting =>
          LocaleKeys.document_plugins_smartEditImproveWriting.tr(),
        makeItLonger => LocaleKeys.document_plugins_smartEditMakeLonger.tr(),
      };
}

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
    String? objectId,
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
    final List<String> ragIds = [];
    if (objectId != null) {
      ragIds.add(objectId);
    }

    final payload = CompleteTextPB(
      text: text,
      completionType: completionType,
      streamPort: fixnum.Int64(stream.nativePort),
      objectId: objectId ?? "",
      ragIds: ragIds,
    );

    // ignore: unawaited_futures
    AIEventCompleteText(payload).send();
    return stream;
  }
}

CompletionTypePB completionTypeFromInt(AskAIAction action) {
  switch (action) {
    case AskAIAction.summarize:
      return CompletionTypePB.MakeShorter;
    case AskAIAction.fixSpelling:
      return CompletionTypePB.SpellingAndGrammar;
    case AskAIAction.improveWriting:
      return CompletionTypePB.ImproveWriting;
    case AskAIAction.makeItLonger:
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

        if (event == "AI_IMAGE_RESPONSE_LIMIT") {
          onError(
            AIError(
              message: LocaleKeys.sideBar_aiImageResponseLimit.tr(),
              code: AIErrorCode.aiImageResponseLimitExceeded,
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
