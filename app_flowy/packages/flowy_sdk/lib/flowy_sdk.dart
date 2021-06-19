export 'cqrs/cqrs.dart';
export 'package:async/async.dart';

import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ffi';
import 'ffi/rust_to_flutter_stream.dart';
import 'ffi/ffi.dart' as ffi;
import 'package:ffi/ffi.dart';

class FlowySDK {
  static const MethodChannel _channel = MethodChannel('flowy_sdk');
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  const FlowySDK();

  void dispose() {
    R2FStream.shared.dispose();
  }

  Future<void> init(Directory sdkDir) async {
    final port = R2FStream.shared.port;
    ffi.init_stream(port);

    ffi.init_logger();
    ffi.store_dart_post_cobject(NativeApi.postCObject);
    print("Application document directory: ${sdkDir.absolute}");
    ffi.init_sdk(sdkDir.path.toNativeUtf8());
  }
}
