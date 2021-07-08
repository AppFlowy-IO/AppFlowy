export 'package:async/async.dart';

import 'dart:io';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'dart:ffi';
import 'dispatch/error.dart';
import 'ffi/ffi.dart' as ffi;
import 'package:ffi/ffi.dart';

import 'package:flowy_sdk/protobuf.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';

class FlowySDK {
  static const MethodChannel _channel = MethodChannel('flowy_sdk');
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  const FlowySDK();

  void dispose() {}

  Future<void> init(Directory sdkDir) async {
    ffi.store_dart_post_cobject(NativeApi.postCObject);

    ffi.init_sdk(sdkDir.path.toNativeUtf8());

    final params = UserSignInParams.create();
    params.email = "nathan.fu@gmail.com";
    params.password = "Helloworld!2";
    Either<UserSignInResult, FlowyError> resp =
        await UserEventSignIn(params).send();

    resp.fold(
      (result) {
        print(result);
      },
      (error) {
        print(error);
      },
    );
  }
}
