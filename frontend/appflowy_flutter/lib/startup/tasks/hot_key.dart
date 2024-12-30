import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:universal_platform/universal_platform.dart';

import '../startup.dart';

class HotKeyTask extends LaunchTask {
  const HotKeyTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    // the hotkey manager is not supported on mobile
    if (UniversalPlatform.isMobile) {
      return;
    }
    await hotKeyManager.unregisterAll();
  }

  @override
  Future<void> dispose() async {}
}
