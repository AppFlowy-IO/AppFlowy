import 'dart:async';
import 'dart:io';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
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
    // TODO: support both dispatchers
    Log.info("init FlowSDK ...");
    final dispatcher = GrpcDispatcher();
    // final dispatcher = FFIDispatcher();
    Dispatch.dispatcher = dispatcher;
    // await dispatcher.init(sdkDir);
    await dispatcher.init(sdkDir);
    Log.info("FlowSDK initialized");
  }
}
