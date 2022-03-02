import 'package:app_flowy/core/network_monitor.dart';
import '../startup.dart';

class InitPlatformServiceTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    getIt<NetworkListener>().start();
  }
}
