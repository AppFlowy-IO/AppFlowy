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
    final dir = directory ?? await appFlowyApplicationDataDirectory();

    final env = getAppFlowyEnv();
    context.getIt<FlowySDK>().setEnv(env);
    await context.getIt<FlowySDK>().init(dir);
  }
}

AppFlowyEnv getAppFlowyEnv() {
  final supabaseConfig = SupabaseConfiguration(
    enable_sync: true,
    url: Env.supabaseUrl,
    anon_key: Env.supabaseAnonKey,
  );

  final appflowyCloudConfig = AppFlowyCloudConfiguration(
    base_url: Env.afCloudBaseUrl,
    ws_base_url: Env.afCloudWSBaseUrl,
    gotrue_url: Env.afCloudGoTrueUrl,
  );

  return AppFlowyEnv(
    supabase_config: supabaseConfig,
    appflowy_cloud_config: appflowyCloudConfig,
  );
}

/// The default directory to store the user data. The directory can be
/// customized by the user via the [ApplicationDataStorage]
Future<Directory> appFlowyApplicationDataDirectory() async {
  switch (integrationMode()) {
    case IntegrationMode.develop:
      final Directory documentsDir = await getApplicationSupportDirectory()
        ..create();
      return Directory(path.join(documentsDir.path, 'data_dev')).create();
    case IntegrationMode.release:
      final Directory documentsDir = await getApplicationSupportDirectory();
      return Directory(path.join(documentsDir.path, 'data')).create();
    case IntegrationMode.unitTest:
    case IntegrationMode.integrationTest:
      return Directory(path.join(Directory.current.path, '.sandbox'));
  }
}
