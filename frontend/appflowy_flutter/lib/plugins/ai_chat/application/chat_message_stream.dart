import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy/ai/service/ai_entities.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_service.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_stream.g.dart';

/// A stream that receives answer events from an isolate or external process.
/// It caches events that might occur before a listener is attached.
class AnswerStream {
  AnswerStream() {
    _port.handler = _controller.add;
    _subscription = _controller.stream.listen(
      _handleEvent,
      onDone: _onDoneCallback,
      onError: _handleError,
    );
  }

  final RawReceivePort _port = RawReceivePort();
  final StreamController<String> _controller = StreamController.broadcast();
  late StreamSubscription<String> _subscription;

  bool _hasStarted = false;
  bool _aiLimitReached = false;
  bool _aiImageLimitReached = false;
  String? _error;
  String _text = "";

  // Callbacks
  void Function(String text)? _onData;
  void Function()? _onStart;
  void Function()? _onEnd;
  void Function(String error)? _onError;
  void Function()? _onLocalAIInitializing;
  void Function()? _onAIResponseLimit;
  void Function()? _onAIImageResponseLimit;
  void Function(String message)? _onAIMaxRequired;
  void Function(MetadataCollection metadata)? _onMetadata;
  void Function(AIQuestionData)? _onAIQuestionData;
  // Caches for events that occur before listen() is called.
  final List<String> _pendingAIMaxRequiredEvents = [];
  bool _pendingLocalAINotReady = false;

  int get nativePort => _port.sendPort.nativePort;
  bool get hasStarted => _hasStarted;
  bool get aiLimitReached => _aiLimitReached;
  bool get aiImageLimitReached => _aiImageLimitReached;
  String? get error => _error;
  String get text => _text;

  /// Releases the resources used by the AnswerStream.
  Future<void> dispose() async {
    await _controller.close();
    await _subscription.cancel();
    _port.close();
  }

  /// Handles incoming events from the underlying stream.
  void _handleEvent(String event) {
    if (event.startsWith(AIStreamEventPrefix.data)) {
      _hasStarted = true;
      final newText = event.substring(AIStreamEventPrefix.data.length);
      _text += newText;
      _onData?.call(_text);
    } else if (event.startsWith(AIStreamEventPrefix.error)) {
      _error = event.substring(AIStreamEventPrefix.error.length);
      _onError?.call(_error!);
    } else if (event.startsWith(AIStreamEventPrefix.metadata)) {
      final s = event.substring(AIStreamEventPrefix.metadata.length);
      _onMetadata?.call(parseMetadata(s));
    } else if (event == AIStreamEventPrefix.aiResponseLimit) {
      _aiLimitReached = true;
      _onAIResponseLimit?.call();
    } else if (event == AIStreamEventPrefix.aiImageResponseLimit) {
      _aiImageLimitReached = true;
      _onAIImageResponseLimit?.call();
    } else if (event.startsWith(AIStreamEventPrefix.aiMaxRequired)) {
      final msg = event.substring(AIStreamEventPrefix.aiMaxRequired.length);
      if (_onAIMaxRequired != null) {
        _onAIMaxRequired!(msg);
      } else {
        _pendingAIMaxRequiredEvents.add(msg);
      }
    } else if (event.startsWith(AIStreamEventPrefix.localAINotReady)) {
      if (_onLocalAIInitializing != null) {
        _onLocalAIInitializing!();
      } else {
        _pendingLocalAINotReady = true;
      }
    } else if (event.startsWith(AIStreamEventPrefix.aiQuestionData)) {
      final s = event.substring(AIStreamEventPrefix.aiQuestionData.length);
      _onAIQuestionData?.call(AIQuestionData.fromJson(jsonDecode(s)));
    }
  }

  void _onDoneCallback() {
    _onEnd?.call();
  }

  void _handleError(dynamic error) {
    _error = error.toString();
    _onError?.call(_error!);
  }

  /// Registers listeners for various events.
  ///
  /// If certain events have already occurred (e.g. AI_MAX_REQUIRED or LOCAL_AI_NOT_READY),
  /// they will be flushed immediately.
  void listen({
    void Function(String text)? onData,
    void Function()? onStart,
    void Function()? onEnd,
    void Function(String error)? onError,
    void Function()? onAIResponseLimit,
    void Function()? onAIImageResponseLimit,
    void Function(String message)? onAIMaxRequired,
    void Function(MetadataCollection metadata)? onMetadata,
    void Function()? onLocalAIInitializing,
    void Function(AIQuestionData)? onAIQuestionData,
  }) {
    _onData = onData;
    _onStart = onStart;
    _onEnd = onEnd;
    _onError = onError;
    _onAIResponseLimit = onAIResponseLimit;
    _onAIImageResponseLimit = onAIImageResponseLimit;
    _onAIMaxRequired = onAIMaxRequired;
    _onMetadata = onMetadata;
    _onLocalAIInitializing = onLocalAIInitializing;
    _onAIQuestionData = onAIQuestionData;
    // Flush pending AI_MAX_REQUIRED events.
    if (_onAIMaxRequired != null && _pendingAIMaxRequiredEvents.isNotEmpty) {
      for (final msg in _pendingAIMaxRequiredEvents) {
        _onAIMaxRequired!(msg);
      }
      _pendingAIMaxRequiredEvents.clear();
    }

    // Flush pending LOCAL_AI_NOT_READY event.
    if (_pendingLocalAINotReady && _onLocalAIInitializing != null) {
      _onLocalAIInitializing!();
      _pendingLocalAINotReady = false;
    }

    _onStart?.call();
  }
}

class QuestionStream {
  QuestionStream() {
    _port.handler = _controller.add;
    _subscription = _controller.stream.listen(
      (event) {
        if (event.startsWith("data:")) {
          _hasStarted = true;
          final newText = event.substring(5);
          _text += newText;
          if (_onData != null) {
            _onData!(_text);
          }
        } else if (event.startsWith("message_id:")) {
          final messageId = event.substring(11);
          _onMessageId?.call(messageId);
        } else if (event.startsWith("start_index_file:")) {
          final indexName = event.substring(17);
          _onFileIndexStart?.call(indexName);
        } else if (event.startsWith("end_index_file:")) {
          final indexName = event.substring(10);
          _onFileIndexEnd?.call(indexName);
        } else if (event.startsWith("index_file_error:")) {
          final indexName = event.substring(16);
          _onFileIndexError?.call(indexName);
        } else if (event.startsWith("index_start:")) {
          _onIndexStart?.call();
        } else if (event.startsWith("index_end:")) {
          _onIndexEnd?.call();
        } else if (event.startsWith("done:")) {
          _onDone?.call();
        } else if (event.startsWith("error:")) {
          _error = event.substring(5);
          if (_onError != null) {
            _onError!(_error!);
          }
        }
      },
      onError: (error) {
        if (_onError != null) {
          _onError!(error.toString());
        }
      },
    );
  }

  final RawReceivePort _port = RawReceivePort();
  final StreamController<String> _controller = StreamController.broadcast();
  late StreamSubscription<String> _subscription;
  bool _hasStarted = false;
  String? _error;
  String _text = "";

  // Callbacks
  void Function(String text)? _onData;
  void Function(String error)? _onError;
  void Function(String messageId)? _onMessageId;
  void Function(String indexName)? _onFileIndexStart;
  void Function(String indexName)? _onFileIndexEnd;
  void Function(String indexName)? _onFileIndexError;
  void Function()? _onIndexStart;
  void Function()? _onIndexEnd;
  void Function()? _onDone;
  int get nativePort => _port.sendPort.nativePort;
  bool get hasStarted => _hasStarted;
  String? get error => _error;
  String get text => _text;

  Future<void> dispose() async {
    await _controller.close();
    await _subscription.cancel();
    _port.close();
  }

  void listen({
    void Function(String text)? onData,
    void Function(String error)? onError,
    void Function(String messageId)? onMessageId,
    void Function(String indexName)? onFileIndexStart,
    void Function(String indexName)? onFileIndexEnd,
    void Function(String indexName)? onFileIndexFail,
    void Function()? onIndexStart,
    void Function()? onIndexEnd,
    void Function()? onDone,
  }) {
    _onData = onData;
    _onError = onError;
    _onMessageId = onMessageId;

    _onFileIndexStart = onFileIndexStart;
    _onFileIndexEnd = onFileIndexEnd;
    _onFileIndexError = onFileIndexFail;

    _onIndexStart = onIndexStart;
    _onIndexEnd = onIndexEnd;
    _onDone = onDone;
  }
}

@JsonSerializable()
class AIQuestionData {
  AIQuestionData({
    required this.data,
    required this.content,
  });

  factory AIQuestionData.fromJson(Map<String, dynamic> json) =>
      _$AIQuestionDataFromJson(json);
  final AIQuestionDataMetadata data;
  final String content;

  Map<String, dynamic> toJson() => _$AIQuestionDataToJson(this);
}

@JsonSerializable()
class AIQuestionDataMetadata {
  factory AIQuestionDataMetadata.fromJson(Map<String, dynamic> json) =>
      _$AIQuestionDataMetadataFromJson(json);

  AIQuestionDataMetadata({
    this.suggestedQuestions,
  });
  @JsonKey(name: 'SuggestedQuestion')
  final List<String>? suggestedQuestions;

  Map<String, dynamic> toJson() => _$AIQuestionDataMetadataToJson(this);
}
