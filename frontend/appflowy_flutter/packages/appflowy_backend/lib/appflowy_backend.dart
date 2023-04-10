import 'dart:async';
import 'dart:io';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:flutter/services.dart';

export 'package:async/async.dart';

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

  void dispose() {}

  Future<void> init(Directory sdkDir) async {
    if (sdkDir.path.toLowerCase().startsWith("grpc://")) {
      Dispatch.dispatcher = GrpcDispatcher.url(sdkDir.path);
    } else {
      Dispatch.dispatcher = FFIDispatcher(path: sdkDir.path);
    }

    await Dispatch.init();
  }
}
