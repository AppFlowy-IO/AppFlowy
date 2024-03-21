import 'package:appflowy/shared/feature_flags.dart';

import '../startup.dart';

class FeatureFlagTask extends LaunchTask {
  const FeatureFlagTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    // if (!kDebugMode) {
    //   return;
    // }

    await FeatureFlag.initialize();
  }

  @override
  Future<void> dispose() async {}
}
