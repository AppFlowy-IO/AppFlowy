import 'package:flowy_sdk/protobuf/dart-ffi/protobuf.dart';

class FlowyError {
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

  FlowyError({required FFIStatusCode statusCode, required String error}) {
    _statusCode = statusCode;
    _error = error;
  }

  factory FlowyError.from(FFIResponse resp) {
    return FlowyError(statusCode: resp.code, error: "");
  }
}

class StackTraceError {
  Object error;
  StackTrace trace;
  StackTraceError(
    this.error,
    this.trace,
  );

  FlowyError asFlowyError() {
    return FlowyError(statusCode: FFIStatusCode.Err, error: this.toString());
  }

  String toString() {
    return '${error.runtimeType}. Stack trace: $trace';
  }
}
