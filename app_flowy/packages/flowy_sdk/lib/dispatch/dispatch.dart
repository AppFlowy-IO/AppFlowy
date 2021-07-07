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
  static Future<FFIResponse> asyncRequest(FFIRequest request) {
    try {
      return _asyncRequest(request).future.then((value) {
        try {
          final response = FFIResponse.fromBuffer(value);
          return Future.microtask(() => response);
        } catch (e, s) {
          Log.error('FlowyFFI asyncRequest error: ${e.runtimeType}\n');
          Log.error('Stack trace \n $s');
          final response = error_response(request, "${e.runtimeType}");
          return Future.microtask(() => response);
        }
      });
    } catch (e, s) {
      Log.error('FlowyFFI asyncRequest error: ${e.runtimeType}\n');
      Log.error('Stack trace \n $s');
      final response = error_response(request, "${e.runtimeType}");
      return Future.microtask(() => response);
    }
  }
}

Completer<Uint8List> _asyncRequest(FFIRequest request) {
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

FFIResponse error_response(FFIRequest request, String message) {
  var response = FFIResponse();
  response.code = FFIStatusCode.Err;
  response.error = "${request.event}: ${message}";
  return response;
}

Either<Uint8List, String> protobufToBytes<T extends GeneratedMessage>(
    T? message) {
  try {
    if (message != null) {
      return left(message.writeToBuffer());
    } else {
      return left(Uint8List.fromList([]));
    }
  } catch (e, s) {
    return right('FlowyFFI error: ${e.runtimeType}. Stack trace: $s');
  }
}
