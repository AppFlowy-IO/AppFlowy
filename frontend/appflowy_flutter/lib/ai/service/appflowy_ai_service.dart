import 'dart:async';
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

import 'ai_entities.dart';
import 'error.dart';

abstract class AIRepository {
  Future<void> streamCompletion({
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
    required void Function() onLocalAIInitializing,
  });
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
    required void Function() onLocalAIInitializing,
  }) async {
    final stream = AppFlowyCompletionStream(
      onStart: onStart,
      processMessage: processMessage,
      processAssistMessage: processAssistMessage,
      processError: onError,
      onLocalAIInitializing: onLocalAIInitializing,
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
}

abstract class CompletionStream {
  CompletionStream({
    required this.onStart,
    required this.processMessage,
    required this.processAssistMessage,
    required this.processError,
    required this.onLocalAIInitializing,
    required this.onEnd,
  });

  final Future<void> Function() onStart;
  final Future<void> Function(String text) processMessage;
  final Future<void> Function(String text) processAssistMessage;
  final void Function(AIError error) processError;
  final void Function() onLocalAIInitializing;
  final Future<void> Function() onEnd;
}

class AppFlowyCompletionStream extends CompletionStream {
  AppFlowyCompletionStream({
    required super.onStart,
    required super.processMessage,
    required super.processAssistMessage,
    required super.processError,
    required super.onEnd,
    required super.onLocalAIInitializing,
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
    final colonIndex = event.indexOf(':');
    final hasColon = colonIndex != -1;
    final prefix = hasColon ? event.substring(0, colonIndex) : event;
    final content = hasColon ? event.substring(colonIndex + 1) : '';

    switch (prefix) {
      case AIStreamEventPrefix.aiMaxRequired:
        processError(AIError(message: content, code: AIErrorCode.other));
        break;

      case AIStreamEventPrefix.start:
        await onStart();
        break;

      case AIStreamEventPrefix.data:
        await processMessage(content);
        break;

      case AIStreamEventPrefix.comment:
        await processAssistMessage(content);
        break;

      case AIStreamEventPrefix.finish:
        await onEnd();
        break;

      case AIStreamEventPrefix.localAINotReady:
        onLocalAIInitializing();
        break;

      case AIStreamEventPrefix.error:
        processError(AIError(message: content, code: AIErrorCode.other));
        break;

      default:
        Log.debug('Unknown AI event: $event');
        break;
    }
  }
}
