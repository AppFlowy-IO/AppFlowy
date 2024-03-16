import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:ffi';
import 'dart:typed_data';

import 'package:appflowy_backend/ffi.dart' as ffi;
import 'package:appflowy_backend/log.dart';
// ignore: unnecessary_import
import 'package:appflowy_backend/protobuf/dart-ffi/ffi_response.pb.dart';
import 'package:appflowy_backend/protobuf/dart-ffi/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:isolates/isolates.dart';
import 'package:isolates/ports.dart';
import 'package:protobuf/protobuf.dart';

import '../protobuf/flowy-config/entities.pb.dart';
import '../protobuf/flowy-config/event_map.pb.dart';
import '../protobuf/flowy-date/entities.pb.dart';
import '../protobuf/flowy-date/event_map.pb.dart';
import 'error.dart';

part 'dart_event/flowy-config/dart_event.dart';
part 'dart_event/flowy-database2/dart_event.dart';
part 'dart_event/flowy-date/dart_event.dart';
part 'dart_event/flowy-document/dart_event.dart';
part 'dart_event/flowy-folder/dart_event.dart';
part 'dart_event/flowy-user/dart_event.dart';

enum FFIException {
  RequestIsEmpty,
}

class DispatchException implements Exception {
  FFIException type;
  DispatchException(this.type);
}

class Dispatch {
  static Future<FlowyResult<Uint8List, Uint8List>> asyncRequest(
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

Future<FlowyResult<Uint8List, Uint8List>> _extractPayload(
    Future<FlowyResult<FFIResponse, FlowyInternalError>> responseFuture) {
  return responseFuture.then((result) {
    return result.fold(
      (response) {
        switch (response.code) {
          case FFIStatusCode.Ok:
            return FlowySuccess(Uint8List.fromList(response.payload));
          case FFIStatusCode.Err:
            return FlowyFailure(Uint8List.fromList(response.payload));
          case FFIStatusCode.Internal:
            final error = utf8.decode(response.payload);
            Log.error("Dispatch internal error: $error");
            return FlowyFailure(emptyBytes());
          default:
            Log.error("Impossible to here");
            return FlowyFailure(emptyBytes());
        }
      },
      (error) {
        Log.error("Response should not be empty $error");
        return FlowyFailure(emptyBytes());
      },
    );
  });
}

Future<FlowyResult<FFIResponse, FlowyInternalError>> _extractResponse(
    Completer<Uint8List> bytesFuture) {
  return bytesFuture.future.then((bytes) {
    try {
      final response = FFIResponse.fromBuffer(bytes);
      return FlowySuccess(response);
    } catch (e, s) {
      final error = StackTraceError(e, s);
      Log.error('Deserialize response failed. ${error.toString()}');
      return FlowyFailure(error.asFlowyError());
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
