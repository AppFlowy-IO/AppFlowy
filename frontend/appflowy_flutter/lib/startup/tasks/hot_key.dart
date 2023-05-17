import 'package:hotkey_manager/hotkey_manager.dart';

import '../startup.dart';

class HotKeyTask extends LaunchTask {
  const HotKeyTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    await hotKeyManager.unregisterAll();
  }
}
