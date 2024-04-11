import 'package:appflowy/core/network_monitor.dart';
import '../startup.dart';

class InitPlatformServiceTask extends LaunchTask {
  const InitPlatformServiceTask();

  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    return getIt<NetworkListener>().start();
  }

  @override
  Future<void> dispose() async {
    await getIt<NetworkListener>().stop();
  }
}
