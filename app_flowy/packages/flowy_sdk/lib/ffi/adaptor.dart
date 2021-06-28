import 'dart:ffi';
// ignore: import_of_legacy_library_into_null_safe
import 'package:isolates/isolates.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:isolates/ports.dart';
import 'package:ffi/ffi.dart';

import 'package:flowy_protobuf/model/grpc.pb.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flowy_sdk/ffi/ffi.dart' as ffi;

enum FFIExceptionType {
  RequestPacketIsEmpty,
  InvalidResponseLength,
  ResponsePacketIsInvalid,
}

class FFIAdaptorException implements Exception {
  FFIExceptionType type;
  FFIAdaptorException(this.type);
}

class FFIAdaptor {
  static Completer<Uint8List> asyncRequest(RequestPacket request) {
    Uint8List bytes = request.writeToBuffer();

    assert(bytes.isEmpty == false);
    if (bytes.isEmpty) {
      throw FFIAdaptorException(FFIExceptionType.RequestPacketIsEmpty);
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
}

