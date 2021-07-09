import 'package:flowy_logger/flowy_logger.dart';
import 'package:flowy_sdk/protobuf/ffi_request.pb.dart';
import 'package:flowy_sdk/protobuf/ffi_response.pb.dart';

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
    return FlowyError(statusCode: resp.code, error: resp.error);
  }

  factory FlowyError.fromError(String error) {
    return FlowyError(statusCode: FFIStatusCode.Err, error: error);
  }
}

class StackTraceError {
  Object error;
  StackTrace trace;
  StackTraceError(
    this.error,
    this.trace,
  );

  FlowyError toFlowyError() {
    Log.error('${error.runtimeType}\n');
    Log.error('Stack trace \n $trace');
    return FlowyError.fromError('${error.runtimeType}. Stack trace: $trace');
  }

  String toString() {
    return '${error.runtimeType}. Stack trace: $trace';
  }
}

FFIResponse error_response(FFIRequest request, StackTraceError error) {
  var response = FFIResponse();
  response.code = FFIStatusCode.Err;
  response.error = error.toString();
  return response;
}
