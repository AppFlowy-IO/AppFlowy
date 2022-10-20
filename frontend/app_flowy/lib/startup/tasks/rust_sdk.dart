import 'dart:io';
import 'package:app_flowy/startup/startup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flowy_sdk/flowy_sdk.dart';

class InitRustSDKTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    await appFlowyDocumentDirectory().then((directory) async {
      await context.getIt<FlowySDK>().init(directory);
    });
  }
}

Future<Directory> appFlowyDocumentDirectory() async {
  switch (integrationEnv()) {
    case IntegrationMode.develop:
      Directory documentsDir = await getApplicationDocumentsDirectory();
      return Directory('${documentsDir.path}/flowy_dev').create();
    case IntegrationMode.release:
      Directory documentsDir = await getApplicationDocumentsDirectory();
      return Directory('${documentsDir.path}/flowy').create();
    case IntegrationMode.test:
      return Directory("${Directory.current.path}/.sandbox");
  }
}
