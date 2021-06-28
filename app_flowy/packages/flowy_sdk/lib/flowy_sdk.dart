export 'package:async/async.dart';

import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ffi';
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

  }

  Future<void> init(Directory sdkDir) async {
    ffi.store_dart_post_cobject(NativeApi.postCObject);
    ffi.init_sdk(sdkDir.path.toNativeUtf8());
  }
}
