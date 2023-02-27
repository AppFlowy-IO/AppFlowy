import 'package:appflowy_backend/protobuf/dart-ffi/protobuf.dart';

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

  FlowyInternalError(
      {required FFIStatusCode statusCode, required String error}) {
    _statusCode = statusCode;
    _error = error;
  }

  factory FlowyInternalError.from(FFIResponse resp) {
    return FlowyInternalError(statusCode: resp.code, error: "");
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
