import 'dart:ffi';
import 'package:dartz/dartz.dart';
import 'package:flowy_logger/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/flowy_error.dart';
import 'package:flowy_sdk/protobuf/ffi_response.pb.dart';
import 'package:isolates/isolates.dart';
import 'package:isolates/ports.dart';
import 'package:ffi/ffi.dart';
// ignore: unused_import
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flowy_sdk/ffi/ffi.dart' as ffi;
import 'package:flowy_sdk/protobuf.dart';
import 'package:protobuf/protobuf.dart';

part 'code_gen.dart';

enum FFIException {
  RequestIsEmpty,
}

class DispatchException implements Exception {
  FFIException type;
  DispatchException(this.type);
}

class Dispatch {
  static Future<Either<Uint8List, FlowyError>> asyncRequest(
      FFIRequest request) {
    // FFIRequest => Rust SDK
    final bytesFuture = _sendToRust(request);

    // Rust SDK => FFIResponse
    final responseFuture = _extractResponse(bytesFuture);

    // FFIResponse's payload is the bytes of the Response object
    final payloadFuture = _extractPayload(responseFuture);

    return payloadFuture;
  }
}

Future<Either<Uint8List, FlowyError>> _extractPayload(
    Future<Either<FFIResponse, FlowyError>> responseFuture) {
  return responseFuture.then((response) {
    return response.fold(
      (l) => left(Uint8List.fromList(l.payload)),
      (r) => right(r),
    );
  });
}

Future<Either<FFIResponse, FlowyError>> _extractResponse(
    Completer<Uint8List> bytesFuture) {
  return bytesFuture.future.then((bytes) {
    try {
      final response = FFIResponse.fromBuffer(bytes);
      if (response.code != FFIStatusCode.Ok) {
        return right(FlowyError.from(response));
      }

      return left(response);
    } catch (e, s) {
      return right(StackTraceError(e, s).toFlowyError());
    }
  });
}

Completer<Uint8List> _sendToRust(FFIRequest request) {
  Uint8List bytes = request.writeToBuffer();
  assert(bytes.isEmpty == false);
  if (bytes.isEmpty) {
    throw DispatchException(FFIException.RequestIsEmpty);
  }

  final Pointer<Uint8> input = calloc.allocate<Uint8>(bytes.length);
  final list = input.asTypedList(bytes.length);
  list.setAll(0, bytes);

  final completer = Completer<Uint8List>();
  final port = singleCompletePort(completer);
  ffi.async_command(port.nativePort, input, bytes.length);
  calloc.free(input);

  return completer;
}

Either<Uint8List, FlowyError> paramsToBytes<T extends GeneratedMessage>(
    T? message) {
  try {
    if (message != null) {
      return left(message.writeToBuffer());
    } else {
      return left(Uint8List.fromList([]));
    }
  } catch (e, s) {
    return right(FlowyError.fromError('${e.runtimeType}. Stack trace: $s'));
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
