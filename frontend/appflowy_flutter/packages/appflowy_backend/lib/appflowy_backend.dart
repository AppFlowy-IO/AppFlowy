export 'package:async/async.dart';
import 'dart:async';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:flutter/services.dart';
import 'dart:ffi';
import 'ffi.dart' as ffi;
import 'package:ffi/ffi.dart';

enum ExceptionType {
  AppearanceSettingsIsEmpty,
}

class FlowySDKException implements Exception {
  ExceptionType type;
  FlowySDKException(this.type);
}

class FlowySDK {
  static const MethodChannel _channel = MethodChannel('appflowy_backend');
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  FlowySDK();

  Future<void> dispose() async {}

  Future<void> init(String configuration) async {
    final port = RustStreamReceiver.shared.port;
    ffi.set_stream_port(port);
    ffi.store_dart_post_cobject(NativeApi.postCObject);

    // final completer = Completer<Uint8List>();
    // // Create a SendPort that accepts only one message.
    // final sendPort = singleCompletePort(completer);

    final code = ffi.init_sdk(0, configuration.toNativeUtf8());
    if (code != 0) {
      throw Exception('Failed to initialize the SDK');
    }
    // return completer.future;
  }
}
