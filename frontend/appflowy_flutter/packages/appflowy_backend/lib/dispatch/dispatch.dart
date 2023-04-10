import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:appflowy_backend/ffi.dart' as ffi;
import 'package:appflowy_backend/log.dart';
// ignore: unnecessary_import
import 'package:appflowy_backend/protobuf/dart-ffi/ffi_response.pb.dart';
import 'package:appflowy_backend/protobuf/dart-ffi/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-grpc/flowygrpc.pbgrpc.dart';
import 'package:appflowy_backend/protobuf/flowy-net/network_state.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:dartz/dartz.dart';
import 'package:ffi/ffi.dart';
// ignore: unused_import
import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:isolates/isolates.dart';
import 'package:isolates/ports.dart';
// ignore: unused_import
import 'package:protobuf/protobuf.dart';

import '../protobuf/flowy-net/event_map.pb.dart';
import 'error.dart';

part 'dart_event/flowy-database/dart_event.dart';
part 'dart_event/flowy-document/dart_event.dart';
part 'dart_event/flowy-folder/dart_event.dart';
part 'dart_event/flowy-net/dart_event.dart';
part 'dart_event/flowy-user/dart_event.dart';

enum FFIException {
  RequestIsEmpty,
}

class DispatchException implements Exception {
  FFIException type;
  DispatchException(this.type);
}

abstract class Dispatcher {
  Future<void> init();

  Future<Either<FFIResponse, FlowyInternalError>> asyncRequest(
      FFIRequest request);

  Future<void> dispose();
}

class FFIDispatcher implements Dispatcher {
  final RawReceivePort _ffiPort = RawReceivePort();
  int get port => _ffiPort.sendPort.nativePort;

  final String path;

  FFIDispatcher({
    required this.path,
  });

  @override
  Future<void> init() async {
    _ffiPort.handler = RustStreamReceiver.shared.add;
    ffi.set_stream_port(port);

    ffi.store_dart_post_cobject(NativeApi.postCObject);
    ffi.init_sdk(path.toNativeUtf8());
  }

  @override
  Future<Either<FFIResponse, FlowyInternalError>> asyncRequest(
      FFIRequest request) {
    // FFIRequest => Rust SDK
    final bytesFuture = _sendToRust(request);

    // Rust SDK => FFIResponse
    return _extractResponse(bytesFuture);
  }

  @override
  Future<void> dispose() async {
    _ffiPort.close();
  }
}

class GrpcDispatcher implements Dispatcher {
  final String host;
  final int port;
  final String path;

  late final ClientChannel _channel;
  ResponseStream<GrpcBytes>? _responseStream;

  GrpcDispatcher({
    required this.host,
    required this.port,
    required this.path,
  }) {
    _channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        codecRegistry:
            CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
      ),
    );
  }

  factory GrpcDispatcher.url(String url) {
    final uri = Uri.parse(url);
    return GrpcDispatcher(
      host: uri.host,
      port: uri.port != 0 ? uri.port : 50051,
      path: uri.path.isEmpty ? "./data" : "${uri.path}",
    );
  }

  @override
  Future<void> init() async {
    final stub = FlowyGRPCClient(_channel);

    _responseStream = await stub.notifyMe(Empty());
    _responseStream?.forEach((grpcBytes) {
      RustStreamReceiver.shared.add(Uint8List.fromList(grpcBytes.bytes));
    });

    await stub.init(GrpcInitRequest(path: path));
  }

  @override
  Future<Either<FFIResponse, FlowyInternalError>> asyncRequest(
      FFIRequest request) async {
    final req = GrpcRequest(
      event: request.event,
      payload: request.payload,
      path: path,
    );
    final stub = FlowyGRPCClient(_channel);

    try {
      final response = await stub.asyncRequest(req);
      return left(FFIResponse(
        code: FFIStatusCode.valueOf(response.code.value),
        payload: response.payload,
      ));
    } catch (e, s) {
      final error = StackTraceError(e, s);
      Log.error('Deserialize response failed. ${error.toString()}');
      return right(error.asFlowyError());
    }
  }

  @override
  Future<void> dispose() async {
    await _responseStream?.cancel();
  }
}

class Dispatch {
  static Dispatcher? dispatcher;

  static Future<Either<Uint8List, Uint8List>> asyncRequest(FFIRequest request) {
    if (dispatcher == null) {
      throw "dispatcher is null";
    }

    // FFIRequest => Rust SDK => FFIResponse
    final responseFuture = dispatcher!.asyncRequest(request);

    // FFIResponse's payload is the bytes of the Response object
    final payloadFuture = _extractPayload(responseFuture);

    return payloadFuture;
  }

  static Future<void> init() async {
    await dispatcher?.init();
  }

  static Future<void> dispose() async {
    await dispatcher?.dispose();
  }
}

Future<Either<Uint8List, Uint8List>> _extractPayload(
    Future<Either<FFIResponse, FlowyInternalError>> responseFuture) {
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

Future<Either<FFIResponse, FlowyInternalError>> _extractResponse(
    Completer<Uint8List> bytesFuture) {
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
