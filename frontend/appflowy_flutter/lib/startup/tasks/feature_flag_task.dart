import 'package:appflowy/shared/feature_flags.dart';
import 'package:flutter/foundation.dart';

import '../startup.dart';

class FeatureFlagTask extends LaunchTask {
  const FeatureFlagTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    // the hotkey manager is not supported on mobile
    if (!kDebugMode) {
      return;
    }

    await FeatureFlag.initialize();
  }

  @override
  Future<void> dispose() async {}
}
