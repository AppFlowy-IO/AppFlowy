import 'dart:io';

import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:path_provider/path_provider.dart';

import '../startup.dart';

class InitRustSDKTask extends LaunchTask {
  InitRustSDKTask({
    this.directory,
  });

  // Customize the RustSDK initialization path
  final Future<Directory>? directory;

  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    // use the custom directory
    if (directory != null) {
      return directory!.then((directory) async {
        await context.getIt<FlowySDK>().init(directory);
      });
    } else {
      return appFlowyDocumentDirectory().then((directory) async {
        await context.getIt<FlowySDK>().init(directory);
      });
    }
  }
}

Future<Directory> appFlowyDocumentDirectory() async {
  switch (integrationEnv()) {
    case IntegrationMode.develop:
      Directory documentsDir = await getApplicationDocumentsDirectory();
      Directory('${documentsDir.path}/flowy_dev/images')
          .create(recursive: true);
      return Directory('${documentsDir.path}/flowy_dev').create();
    case IntegrationMode.release:
      Directory documentsDir = await getApplicationDocumentsDirectory();
      Directory('${documentsDir.path}/flowy/images')
          .create(recursive: true);
      return Directory('${documentsDir.path}/flowy').create();
    case IntegrationMode.test:
      return Directory("${Directory.current.path}/.sandbox");
  }
}
