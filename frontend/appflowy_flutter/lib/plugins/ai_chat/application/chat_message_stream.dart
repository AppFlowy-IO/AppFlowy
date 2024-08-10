import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
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
          if (_onData != null) {
            _onData!(_text);
          }
        } else if (event.startsWith("error:")) {
          _error = event.substring(5);
          if (_onError != null) {
            _onError!(_error!);
          }
        } else if (event.startsWith("metadata:")) {
          if (_onMetadata != null) {
            final s = event.substring(9);
            _onMetadata!(messageRefSourceFromString(s));
          }
        } else if (event == "AI_RESPONSE_LIMIT") {
          if (_onAIResponseLimit != null) {
            _onAIResponseLimit!();
          }
        }
      },
      onDone: () {
        if (_onEnd != null) {
          _onEnd!();
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
  void Function()? _onStart;
  void Function()? _onEnd;
  void Function(String error)? _onError;
  void Function()? _onAIResponseLimit;
  void Function(List<ChatMessageRefSource> metadata)? _onMetadata;

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
    void Function()? onStart,
    void Function()? onEnd,
    void Function(String error)? onError,
    void Function()? onAIResponseLimit,
    void Function(List<ChatMessageRefSource> metadata)? onMetadata,
  }) {
    _onData = onData;
    _onStart = onStart;
    _onEnd = onEnd;
    _onError = onError;
    _onAIResponseLimit = onAIResponseLimit;
    _onMetadata = onMetadata;

    if (_onStart != null) {
      _onStart!();
    }
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
        } else if (event.startsWith("error:")) {
          _error = event.substring(5);
          if (_onError != null) {
            _onError!(_error!);
          }
        }
      },
      onDone: () {
        if (_onEnd != null) {
          _onEnd!();
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
  void Function()? _onStart;
  void Function()? _onEnd;
  void Function(String error)? _onError;

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
    void Function()? onStart,
    void Function()? onEnd,
    void Function(String error)? onError,
  }) {
    _onData = onData;
    _onStart = onStart;
    _onEnd = onEnd;
    _onError = onError;

    if (_onStart != null) {
      _onStart!();
    }
  }
}
