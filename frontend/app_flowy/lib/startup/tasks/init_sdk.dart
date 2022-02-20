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
      case IntegrationEnv.develop:
      case IntegrationEnv.release:
        Directory directory = await getApplicationDocumentsDirectory();
        return Directory('${directory.path}/flowy').create().then(
          (Directory directory) async {
            await context.getIt<FlowySDK>().init(directory);
          },
        );
      case IntegrationEnv.test:
        await context.getIt<FlowySDK>().init(testDir());
        break;
      default:
        assert(false, 'Unsupported env');
    }
  }

  Directory testDir() {
    return Directory("${Directory.current.path}/.appflowy_dev");
  }
}
