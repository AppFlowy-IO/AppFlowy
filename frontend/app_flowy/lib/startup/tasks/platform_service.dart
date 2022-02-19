import 'package:app_flowy/user/infrastructure/network_monitor.dart';
import '../startup.dart';

class InitPlatformService extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    getIt<NetworkMonitor>().start();
  }
}
