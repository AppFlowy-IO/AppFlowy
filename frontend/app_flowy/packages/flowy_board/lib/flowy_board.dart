
import 'flowy_board_platform_interface.dart';

class FlowyBoard {
  Future<String?> getPlatformVersion() {
    return FlowyBoardPlatform.instance.getPlatformVersion();
  }
}
