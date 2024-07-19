import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/dart-ffi/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
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

class ErrorCodeNotifier extends ChangeNotifier {
  // Static instance
  static final ErrorCodeNotifier _instance = ErrorCodeNotifier();

  // Factory constructor to return the same instance
  factory ErrorCodeNotifier() {
    return _instance;
  }

  FlowyError? _error;

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

  static void onError(
    void Function(FlowyError error) onError,
    bool Function(ErrorCode code)? onErrorIf,
  ) {
    _instance.addListener(() {
      final error = _instance._error;
      if (error != null) {
        if (onErrorIf == null || onErrorIf(error.code)) {
          onError(error);
        }
      }
    });
  }
}
