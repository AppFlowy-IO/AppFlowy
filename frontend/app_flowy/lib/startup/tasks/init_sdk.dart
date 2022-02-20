import 'dart:io';
import 'package:app_flowy/startup/startup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flowy_sdk/flowy_sdk.dart';

class InitRustSDKTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    switch (context.env) {
      case IntegrationMode.release:
        Directory documentsDir = await getApplicationDocumentsDirectory();
        return Directory('${documentsDir.path}/flowy').create().then(
          (Directory directory) async {
            await context.getIt<FlowySDK>().init(directory);
          },
        );
      case IntegrationMode.develop:
        Directory documentsDir = await getApplicationDocumentsDirectory();
        return Directory('${documentsDir.path}/flowy_dev').create().then(
          (Directory directory) async {
            await context.getIt<FlowySDK>().init(directory);
          },
        );
      case IntegrationMode.test:
        final directory = Directory("${Directory.current.path}/.sandbox");
        await context.getIt<FlowySDK>().init(directory);
        break;
      default:
        assert(false, 'Unsupported env');
    }
  }
}
