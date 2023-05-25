import 'package:appflowy/window/app_window_size_manager.dart';
import 'package:window_manager/window_manager.dart';

class AppWindowListener with WindowListener {
  void start() {
    windowManager.addListener(this);
  }

  @override
  Future<void> onWindowResize() async {
    final currentWindowSize = await WindowManager.instance.getSize();
    WindowSizeManager()
        .saveSize(currentWindowSize.height, currentWindowSize.width);
  }
}
