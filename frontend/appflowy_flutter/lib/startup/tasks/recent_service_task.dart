import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/recent/prelude.dart';
import 'package:appflowy_backend/log.dart';

class RecentServiceTask extends LaunchTask {
  const RecentServiceTask();

  @override
  Future<void> initialize(LaunchContext context) async =>
      Log.info('[CachedRecentService] Initialized');

  @override
  Future<void> dispose() async => getIt<CachedRecentService>().dispose();
}
