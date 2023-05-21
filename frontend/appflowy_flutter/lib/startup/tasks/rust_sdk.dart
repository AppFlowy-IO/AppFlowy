import 'dart:io';

import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../startup.dart';

class InitRustSDKTask extends LaunchTask {
  const InitRustSDKTask({
    this.directory,
  });

  // Customize the RustSDK initialization path
  final Directory? directory;

  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    final dir = directory ?? await appFlowyDocumentDirectory();
    await context.getIt<FlowySDK>().init(dir);
  }
}

Future<Directory> appFlowyDocumentDirectory() async {
  switch (integrationEnv()) {
    case IntegrationMode.develop:
      Directory documentsDir = await getApplicationDocumentsDirectory()
        ..create();
      return Directory(path.join(documentsDir.path, 'data_dev')).create();
    case IntegrationMode.release:
      Directory documentsDir = await getApplicationDocumentsDirectory();
      return Directory(path.join(documentsDir.path, 'data')).create();
    case IntegrationMode.test:
      return Directory(path.join(Directory.current.path, '.sandbox'));
  }
}
