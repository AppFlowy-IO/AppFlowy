import 'dart:convert';
import 'dart:ffi';
// ignore: import_of_legacy_library_into_null_safe
import 'package:isolates/isolates.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:isolates/ports.dart';
import 'package:ffi/ffi.dart';
// ignore: unused_import
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

class FFICommand {
  final String event;
  final Uint8List payload;
  FFICommand(this.event, this.payload);

  Map<String, dynamic> toJson() => {
        'event': event,
        'payload': payload,
      };
}

class FFIAdaptor {
  static Completer<Uint8List> asyncRequest() {
    // final command = FFICommand(
    //     "AuthCheck", Uint8List.fromList(utf8.encode("this is payload")));

    final command = FFICommand("AuthCheck", Uint8List(0));

    Uint8List bytes = Uint8List.fromList(utf8.encode(jsonEncode(command)));

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
