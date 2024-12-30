import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy/plugins/ai_chat/application/chat_message_service.dart';

class AnswerStream {
  AnswerStream() {
    _port.handler = _controller.add;
    _subscription = _controller.stream.listen(
      (event) {
        if (event.startsWith("data:")) {
          _hasStarted = true;
          final newText = event.substring(5);
          _text += newText;
          _onData?.call(_text);
        } else if (event.startsWith("error:")) {
          _error = event.substring(5);
          _onError?.call(_error!);
        } else if (event.startsWith("metadata:")) {
          if (_onMetadata != null) {
            final s = event.substring(9);
            _onMetadata!(parseMetadata(s));
          }
        } else if (event == "AI_RESPONSE_LIMIT") {
          _aiLimitReached = true;
          _onAIResponseLimit?.call();
        }
      },
      onDone: () {
        _onEnd?.call();
      },
      onError: (error) {
        _onError?.call(error.toString());
      },
    );
  }

  final RawReceivePort _port = RawReceivePort();
  final StreamController<String> _controller = StreamController.broadcast();
  late StreamSubscription<String> _subscription;
  bool _hasStarted = false;
  bool _aiLimitReached = false;
  String? _error;
  String _text = "";

  // Callbacks
  void Function(String text)? _onData;
  void Function()? _onStart;
  void Function()? _onEnd;
  void Function(String error)? _onError;
  void Function()? _onAIResponseLimit;
  void Function(MetadataCollection metadataCollection)? _onMetadata;

  int get nativePort => _port.sendPort.nativePort;
  bool get hasStarted => _hasStarted;
  bool get aiLimitReached => _aiLimitReached;
  String? get error => _error;
  String get text => _text;

  Future<void> dispose() async {
    await _controller.close();
    await _subscription.cancel();
    _port.close();
  }

  void listen({
    void Function(String text)? onData,
    void Function()? onStart,
    void Function()? onEnd,
    void Function(String error)? onError,
    void Function()? onAIResponseLimit,
    void Function(MetadataCollection metadata)? onMetadata,
  }) {
    _onData = onData;
    _onStart = onStart;
    _onEnd = onEnd;
    _onError = onError;
    _onAIResponseLimit = onAIResponseLimit;
    _onMetadata = onMetadata;

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
