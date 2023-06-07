import 'dart:io';

import 'package:appflowy/env/env.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:appflowy_backend/env_serde.dart';
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

    context.getIt<FlowySDK>().setEnv(getAppFlowyEnv());
    await context.getIt<FlowySDK>().init(dir);
  }
}

AppFlowyEnv getAppFlowyEnv() {
  final supabaseConfig = SupabaseConfiguration(
    url: Env.supabaseUrl,
    key: Env.supabaseKey,
    jwt_secret: Env.supabaseJwtSecret,
  );

  final collabTableConfig =
      CollabTableConfig(enable: true, table_name: Env.supabaseCollabTable);

  final supbaseDBConfig = SupabaseDBConfig(
    url: Env.supabaseUrl,
    key: Env.supabaseKey,
    jwt_secret: Env.supabaseJwtSecret,
    collab_table_config: collabTableConfig,
  );

  return AppFlowyEnv(
    supabase_config: supabaseConfig,
    supabase_db_config: supbaseDBConfig,
  );
}

Future<Directory> appFlowyDocumentDirectory() async {
  switch (integrationEnv()) {
    case IntegrationMode.develop:
      final Directory documentsDir = await getApplicationSupportDirectory()
        ..create();
      return Directory(path.join(documentsDir.path, 'data_dev')).create();
    case IntegrationMode.release:
      final Directory documentsDir = await getApplicationSupportDirectory();
      return Directory(path.join(documentsDir.path, 'data')).create();
    case IntegrationMode.test:
      return Directory(path.join(Directory.current.path, '.sandbox'));
  }
}
