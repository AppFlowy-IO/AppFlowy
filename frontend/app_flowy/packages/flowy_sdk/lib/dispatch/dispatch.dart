import 'dart:ffi';
import 'package:dartz/dartz.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/dart-ffi/ffi_response.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/event.pb.dart';
import 'package:flowy_sdk/protobuf/lib-infra/network_state.pb.dart';
import 'package:isolates/isolates.dart';
import 'package:isolates/ports.dart';
import 'package:ffi/ffi.dart';
// ignore: unused_import
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flowy_sdk/ffi.dart' as ffi;
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_sdk/protobuf/dart-ffi/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-document-infra/protobuf.dart';

// ignore: unused_import
import 'package:flowy_sdk/protobuf/flowy-infra/protobuf.dart';
import 'package:protobuf/protobuf.dart';
import 'dart:convert' show utf8;
import 'error.dart';

part 'code_gen.dart';

enum FFIException {
  RequestIsEmpty,
}

class DispatchException implements Exception {
  FFIException type;
  DispatchException(this.type);
}

class Dispatch {
  static Future<Either<Uint8List, Uint8List>> asyncRequest(FFIRequest request) {
    // FFIRequest => Rust SDK
    final bytesFuture = _sendToRust(request);

    // Rust SDK => FFIResponse
    final responseFuture = _extractResponse(bytesFuture);

    // FFIResponse's payload is the bytes of the Response object
    final payloadFuture = _extractPayload(responseFuture);

    return payloadFuture;
  }
}

Future<Either<Uint8List, Uint8List>> _extractPayload(Future<Either<FFIResponse, FlowyError>> responseFuture) {
  return responseFuture.then((result) {
    return result.fold(
      (response) {
        switch (response.code) {
          case FFIStatusCode.Ok:
            return left(Uint8List.fromList(response.payload));
          case FFIStatusCode.Err:
            return right(Uint8List.fromList(response.payload));
          case FFIStatusCode.Internal:
            final error = utf8.decode(response.payload);
            Log.error("Dispatch internal error: $error");
            return right(emptyBytes());
          default:
            Log.error("Impossible to here");
            return right(emptyBytes());
        }
      },
      (error) {
        Log.error("Response should not be empty $error");
        return right(emptyBytes());
      },
    );
  });
}

Future<Either<FFIResponse, FlowyError>> _extractResponse(Completer<Uint8List> bytesFuture) {
  return bytesFuture.future.then((bytes) {
    try {
      final response = FFIResponse.fromBuffer(bytes);
      return left(response);
    } catch (e, s) {
      final error = StackTraceError(e, s);
      Log.error('Deserialize response failed. ${error.toString()}');
      return right(error.asFlowyError());
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
  ffi.async_event(port.nativePort, input, bytes.length);
  calloc.free(input);

  return completer;
}

Uint8List requestToBytes<T extends GeneratedMessage>(T? message) {
  try {
    if (message != null) {
      return message.writeToBuffer();
    } else {
      return emptyBytes();
    }
  } catch (e, s) {
    final error = StackTraceError(e, s);
    Log.error('Serial request failed. ${error.toString()}');
    return emptyBytes();
  }
}

Uint8List emptyBytes() {
  return Uint8List.fromList([]);
}
