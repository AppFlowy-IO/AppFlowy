import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/dart-ffi/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flutter/foundation.dart';

class FlowyInternalError {
  late FFIStatusCode _statusCode;
  late String _error;

  FFIStatusCode get statusCode {
    return _statusCode;
  }

  String get error {
    return _error;
  }

  bool get has_error {
    return _statusCode != FFIStatusCode.Ok;
  }

  String toString() {
    return "$_statusCode: $_error";
  }

  FlowyInternalError({
    required FFIStatusCode statusCode,
    required String error,
  }) {
    _statusCode = statusCode;
    _error = error;
  }
}

class StackTraceError {
  Object error;
  StackTrace trace;
  StackTraceError(
    this.error,
    this.trace,
  );

  FlowyInternalError asFlowyError() {
    return FlowyInternalError(
        statusCode: FFIStatusCode.Err, error: this.toString());
  }

  String toString() {
    return '${error.runtimeType}. Stack trace: $trace';
  }
}

typedef void ErrorListener();

class GlobalErrorCodeNotifier extends ChangeNotifier {
  // Static instance with lazy initialization
  static final GlobalErrorCodeNotifier _instance =
      GlobalErrorCodeNotifier._internal();

  FlowyError? _error;

  // Private internal constructor
  GlobalErrorCodeNotifier._internal();

  // Factory constructor to return the same instance
  factory GlobalErrorCodeNotifier() {
    return _instance;
  }

  static void receiveError(FlowyError error) {
    if (_instance._error?.code != error.code) {
      _instance._error = error;
      _instance.notifyListeners();
    }
  }

  static void receiveErrorBytes(Uint8List bytes) {
    try {
      final error = FlowyError.fromBuffer(bytes);
      if (_instance._error?.code != error.code) {
        _instance._error = error;
        _instance.notifyListeners();
      }
    } catch (e) {
      Log.error("Can not parse error bytes: $e");
    }
  }

  static ErrorListener add({
    required void Function(FlowyError error) onError,
    bool Function(FlowyError code)? onErrorIf,
  }) {
    void listener() {
      final error = _instance._error;
      if (error != null) {
        if (onErrorIf == null || onErrorIf(error)) {
          onError(error);
        }
      }
    }

    _instance.addListener(listener);
    return listener;
  }

  static void remove(ErrorListener listener) {
    _instance.removeListener(listener);
  }
}
