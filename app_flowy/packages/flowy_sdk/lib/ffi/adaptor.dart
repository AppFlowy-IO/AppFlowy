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

  static Completer<Uint8List> asyncQuery(RequestPacket request) {
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
    ffi.async_query(port.nativePort, input, bytes.length);
    calloc.free(input);

    return completer;
  }

  //https://suragch.medium.com/working-with-bytes-in-dart-6ece83455721
  static FFISafeUint8Wrapper syncRequest(RequestPacket request) {
    Uint8List bytes;
    try {
      bytes = request.writeToBuffer();
    } catch (e, s) {
      //TODO nathan: upload the log
      print('Sync RequestPacket writeToBuffer error: ${e.runtimeType}');
      print('Stack trace \n $s');
      rethrow;
    }

    assert(bytes.isEmpty == false);
    if (bytes.isEmpty) {
      throw FFIAdaptorException(FFIExceptionType.RequestPacketIsEmpty);
    }

    final Pointer<Uint8> dartPtr = _pointerFromBytes(bytes);
    Pointer<Uint8> rustPtr = ffi.sync_command(dartPtr, bytes.length);
    calloc.free(dartPtr);
    FFISafeUint8Wrapper safeWrapper;
    try {
      safeWrapper = FFISafeUint8Wrapper(rustPtr);
    } catch (_) {
      rethrow;
    }
    return safeWrapper;
  }

  // inline?
  static Pointer<Uint8> _pointerFromBytes(Uint8List bytes) {
    final Pointer<Uint8> ptr = calloc.allocate<Uint8>(bytes.length);
    final list = ptr.asTypedList(bytes.length);
    list.setAll(0, bytes);
    return ptr;
  }
}

class FFISafeUint8Wrapper {
  Pointer<Uint8> _ptr;
  int _responseBytesLen = 0;
  int _markerBytesLen = 4;
  FFISafeUint8Wrapper(this._ptr) {
    try {
      this._responseBytesLen =
          ByteData.sublistView(_ptr.asTypedList(_markerBytesLen))
              .getUint32(0, Endian.big);
    } catch (_) {
      throw FFIAdaptorException(FFIExceptionType.RequestPacketIsEmpty);
    }

    if (this._responseBytesLen < _markerBytesLen) {
      throw FFIAdaptorException(FFIExceptionType.ResponsePacketIsInvalid);
    }
  }

  void destroy() {
    ffi.free_rust(_ptr, _responseBytesLen + _markerBytesLen);
  }

  Uint8List buffer() {
    Pointer<Uint8> respPtr = _ptr.elementAt(_markerBytesLen);
    return respPtr.asTypedList(_responseBytesLen);
  }
}
