import 'package:dartz/dartz.dart';
import 'package:flowy_protobuf/remote.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:protobuf/protobuf.dart';
import 'package:flowy_sdk/ffi/adaptor.dart';
import 'dart:typed_data';
import 'package:flowy_logger/flowy_logger.dart';

Either<Uint8List, String> protobufToBytes<T extends GeneratedMessage>(
    T? message) {
  try {
    if (message != null) {
      return left(message.writeToBuffer());
    } else {
      return left(Uint8List.fromList([]));
    }
  } catch (e, s) {
    return right(
        'FlowyFFI syncRequest  error: ${e.runtimeType}. Stack trace: $s');
  }
}

Future<ResponsePacket> asyncCommand(RequestPacket request) {
  try {
    return FFIAdaptor.asyncRequest(request).future.then((value) {
      try {
        final resp = ResponsePacket.fromBuffer(value);
        return Future.microtask(() => resp);
      } catch (e, s) {
        Log.error('FlowyFFI asyncRequest error: ${e.runtimeType}\n');
        Log.error('Stack trace \n $s');
        final resp = responseFromRequest(
            request, "FlowyFFI asyncRequest error: ${e.runtimeType}");
        return Future.microtask(() => resp);
      }
    });
  } catch (e, s) {
    Log.error('FlowyFFI asyncRequest error: ${e.runtimeType}\n');
    Log.error('Stack trace \n $s');
    final resp = responseFromRequest(
        request, "FlowyFFI asyncRequest error: ${e.runtimeType}");
    return Future.microtask(() => resp);
  }
}

Future<ResponsePacket> asyncQuery(RequestPacket request) {
  try {
    return FFIAdaptor.asyncQuery(request).future.then((value) {
      try {
        final resp = ResponsePacket.fromBuffer(value);
        return Future.microtask(() => resp);
      } catch (e, s) {
        Log.error('FlowyFFI asyncRequest error: ${e.runtimeType}\n');
        Log.error('Stack trace \n $s');
        final resp = responseFromRequest(
            request, "FlowyFFI asyncRequest error: ${e.runtimeType}");
        return Future.microtask(() => resp);
      }
    });
  } catch (e, s) {
    Log.error('FlowyFFI asyncRequest error: ${e.runtimeType}\n');
    Log.error('Stack trace \n $s');
    final resp = responseFromRequest(
        request, "FlowyFFI asyncRequest error: ${e.runtimeType}");
    return Future.microtask(() => resp);
  }
}

ResponsePacket responseFromRequest(RequestPacket request, String message) {
  var resp = ResponsePacket();
  resp.id = request.id;
  resp.statusCode = StatusCode.Fail;
  resp.command = request.command;
  resp.err = message;

  return resp;
}
