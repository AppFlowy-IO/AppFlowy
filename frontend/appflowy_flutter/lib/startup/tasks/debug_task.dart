import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../startup.dart';

class DebugTask extends LaunchTask {
  const DebugTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    // the hotkey manager is not supported on mobile
    if (PlatformExtension.isMobile && kDebugMode) {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  @override
  Future<void> dispose() async {}
}
