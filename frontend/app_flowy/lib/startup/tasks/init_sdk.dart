import 'dart:io';
import 'package:app_flowy/startup/launcher.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flowy_sdk/flowy_sdk.dart';
import 'package:flutter/material.dart';

class InitRustSDKTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory directory = await getApplicationDocumentsDirectory();
    final documentPath = directory.path;

    return Directory('$documentPath/flowy').create().then((Directory directory) async {
      switch (context.env) {
        case IntegrationEnv.dev:
          // await context.getIt<FlowySDK>().init(Directory('./temp/flowy_dev'));
          await context.getIt<FlowySDK>().init(directory);
          break;
        case IntegrationEnv.pro:
          await context.getIt<FlowySDK>().init(directory);
          break;
        default:
          assert(false, 'Unsupported env');
      }
    });
  }
}
