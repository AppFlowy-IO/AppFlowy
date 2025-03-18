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
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
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
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  }) async {
    final stream = AppFlowyCompletionStream(
      onStart: onStart,
      onProcess: onProcess,
      onEnd: onEnd,
      onError: onError,
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
    required this.onProcess,
    required this.onEnd,
    required this.onError,
  });

  final Future<void> Function() onStart;
  final Future<void> Function(String text) onProcess;
  final Future<void> Function() onEnd;
  final void Function(AIError error) onError;
}

class AppFlowyCompletionStream extends CompletionStream {
  AppFlowyCompletionStream({
    required super.onStart,
    required super.onProcess,
    required super.onEnd,
    required super.onError,
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
        if (event == "AI_RESPONSE_LIMIT") {
          onError(
            AIError(
              message: LocaleKeys.ai_textLimitReachedDescription.tr(),
              code: AIErrorCode.aiResponseLimitExceeded,
            ),
          );
        }

        if (event == "AI_IMAGE_RESPONSE_LIMIT") {
          onError(
            AIError(
              message: LocaleKeys.ai_imageLimitReachedDescription.tr(),
              code: AIErrorCode.aiImageResponseLimitExceeded,
            ),
          );
        }

        if (event.startsWith("AI_MAX_REQUIRED:")) {
          final msg = event.substring(16);
          onError(
            AIError(
              message: msg,
              code: AIErrorCode.other,
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
          onError(
            AIError(message: event.substring(6), code: AIErrorCode.other),
          );
        }
      },
    );
  }

  Future<void> dispose() async {
    await _controller.close();
    await _subscription.cancel();
    _port.close();
  }
}
