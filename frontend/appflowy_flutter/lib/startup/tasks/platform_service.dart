import 'package:appflowy/core/network_monitor.dart';
import '../startup.dart';

class InitPlatformServiceTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(final LaunchContext context) async {
    getIt<NetworkListener>().start();
  }
}
