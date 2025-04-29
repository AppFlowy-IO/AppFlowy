import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/operations/ai_writer_entities.dart';
import 'package:appflowy/shared/list_extension.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter/services.dart';

import 'ai_entities.dart';
import 'error.dart';

enum LocalAIStreamingState {
  notReady,
  disabled,
}

abstract class AIRepository {
  Future<(String, CompletionStream)?> streamCompletion({
    String? objectId,
    required String text,
    PredefinedFormat? format,
    List<String> sourceIds = const [],
    List<AiWriterRecord> history = const [],
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) processMessage,
    required Future<void> Function(String text) processAssistMessage,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
    required void Function(LocalAIStreamingState state)
        onLocalAIStreamingStateChange,
  });

  Future<List<AiPrompt>> getBuiltInPrompts();

  void updateFavoritePrompts(List<String> promptIds);
}

class AppFlowyAIService implements AIRepository {
  @override
  Future<(String, CompletionStream)?> streamCompletion({
    String? objectId,
    required String text,
    PredefinedFormat? format,
    List<String> sourceIds = const [],
    List<AiWriterRecord> history = const [],
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) processMessage,
    required Future<void> Function(String text) processAssistMessage,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
    required void Function(LocalAIStreamingState state)
        onLocalAIStreamingStateChange,
  }) async {
    final stream = AppFlowyCompletionStream(
      onStart: onStart,
      processMessage: processMessage,
      processAssistMessage: processAssistMessage,
      processError: onError,
      onLocalAIStreamingStateChange: onLocalAIStreamingStateChange,
      onEnd: onEnd,
    );

    final records = history.map((record) => record.toPB()).toList();

    final payload = CompleteTextPB(
      text: text,
      completionType: completionType,
      format: format?.toPB(),
      streamPort: fixnum.Int64(stream.nativePort),
      objectId: objectId ?? '',
      ragIds: [
        if (objectId != null) objectId,
        ...sourceIds,
      ].unique(),
      history: records,
    );

    return AIEventCompleteText(payload).send().fold(
      (task) => (task.taskId, stream),
      (error) {
        Log.error(error);
        return null;
      },
    );
  }

  @override
  Future<List<AiPrompt>> getBuiltInPrompts() async {
    final prompts = <AiPrompt>[];

    try {
      final jsonString =
          await rootBundle.loadString('assets/built_in_prompts.json');
      // final data = await rootBundle.load('assets/built_in_prompts.json');
      // final jsonString = utf8.decode(data.buffer.asUint8List());
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final promptJson = jsonData['prompts'] as List<dynamic>;
      prompts.addAll(
        promptJson
            .map((e) => AiPrompt.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      Log.error(e);
    }

    return prompts;
  }

  @override
  void updateFavoritePrompts(List<String> promptIds) {}
}

abstract class CompletionStream {
  CompletionStream({
    required this.onStart,
    required this.processMessage,
    required this.processAssistMessage,
    required this.processError,
    required this.onLocalAIStreamingStateChange,
    required this.onEnd,
  });

  final Future<void> Function() onStart;
  final Future<void> Function(String text) processMessage;
  final Future<void> Function(String text) processAssistMessage;
  final void Function(AIError error) processError;
  final void Function(LocalAIStreamingState state)
      onLocalAIStreamingStateChange;
  final Future<void> Function() onEnd;
}

class AppFlowyCompletionStream extends CompletionStream {
  AppFlowyCompletionStream({
    required super.onStart,
    required super.processMessage,
    required super.processAssistMessage,
    required super.processError,
    required super.onEnd,
    required super.onLocalAIStreamingStateChange,
  }) {
    _startListening();
  }

  final RawReceivePort _port = RawReceivePort();
  final StreamController<String> _controller = StreamController.broadcast();
  late StreamSubscription<String> _subscription;
  int get nativePort => _port.sendPort.nativePort;

  void _startListening() {
    _port.handler = _controller.add;
    _subscription = _controller.stream.listen(
      (event) async {
        await _handleEvent(event);
      },
    );
  }

  Future<void> dispose() async {
    await _controller.close();
    await _subscription.cancel();
    _port.close();
  }

  Future<void> _handleEvent(String event) async {
    // Check simple matches first
    if (event == AIStreamEventPrefix.aiResponseLimit) {
      processError(
        AIError(
          message: LocaleKeys.ai_textLimitReachedDescription.tr(),
          code: AIErrorCode.aiResponseLimitExceeded,
        ),
      );
      return;
    }

    if (event == AIStreamEventPrefix.aiImageResponseLimit) {
      processError(
        AIError(
          message: LocaleKeys.ai_imageLimitReachedDescription.tr(),
          code: AIErrorCode.aiImageResponseLimitExceeded,
        ),
      );
      return;
    }

    // Otherwise, parse out prefix:content
    if (event.startsWith(AIStreamEventPrefix.aiMaxRequired)) {
      processError(
        AIError(
          message: event.substring(AIStreamEventPrefix.aiMaxRequired.length),
          code: AIErrorCode.other,
        ),
      );
    } else if (event.startsWith(AIStreamEventPrefix.start)) {
      await onStart();
    } else if (event.startsWith(AIStreamEventPrefix.data)) {
      await processMessage(
        event.substring(AIStreamEventPrefix.data.length),
      );
    } else if (event.startsWith(AIStreamEventPrefix.comment)) {
      await processAssistMessage(
        event.substring(AIStreamEventPrefix.comment.length),
      );
    } else if (event.startsWith(AIStreamEventPrefix.finish)) {
      await onEnd();
    } else if (event.startsWith(AIStreamEventPrefix.localAIDisabled)) {
      onLocalAIStreamingStateChange(
        LocalAIStreamingState.disabled,
      );
    } else if (event.startsWith(AIStreamEventPrefix.localAINotReady)) {
      onLocalAIStreamingStateChange(
        LocalAIStreamingState.notReady,
      );
    } else if (event.startsWith(AIStreamEventPrefix.error)) {
      processError(
        AIError(
          message: event.substring(AIStreamEventPrefix.error.length),
          code: AIErrorCode.other,
        ),
      );
    } else {
      Log.debug('Unknown AI event: $event');
    }
  }
}
