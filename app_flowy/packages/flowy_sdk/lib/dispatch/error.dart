import 'package:flowy_logger/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/flowy_error.dart';
import 'package:flowy_sdk/protobuf/ffi_request.pb.dart';
import 'package:flowy_sdk/protobuf/ffi_response.pb.dart';

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
