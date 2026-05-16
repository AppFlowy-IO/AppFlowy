import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';

class RecentServiceTask extends LaunchTask {
  const RecentServiceTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    await super.initialize(context);

    Log.info('[CachedRecentService] Initialized');
  }
}
