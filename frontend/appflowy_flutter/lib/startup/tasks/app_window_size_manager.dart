import 'dart:convert';
import 'dart:ui';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';

class WindowSizeManager {
  static const double minWindowHeight = 600.0;
  static const double minWindowWidth = 800.0;
  // Preventing failed assertion due to Texture Descriptor Validation
  static const double maxWindowHeight = 8192.0;
  static const double maxWindowWidth = 8192.0;

  static const width = 'width';
  static const height = 'height';

  static const String dx = 'dx';
  static const String dy = 'dy';

  Future<void> setSize(Size size) async {
    final windowSize = {
      height: size.height.clamp(minWindowHeight, maxWindowHeight),
      width: size.width.clamp(minWindowWidth, maxWindowWidth),
    };

    await getIt<KeyValueStorage>().set(
      KVKeys.windowSize,
      jsonEncode(windowSize),
    );
  }

  Future<Size> getSize() async {
    final defaultWindowSize = jsonEncode(
      {WindowSizeManager.height: 600.0, WindowSizeManager.width: 800.0},
    );
    final windowSize = await getIt<KeyValueStorage>().get(KVKeys.windowSize);
    final size = json.decode(
      windowSize ?? defaultWindowSize,
    );
    final double width = size[WindowSizeManager.width] ?? minWindowWidth;
    final double height = size[WindowSizeManager.height] ?? minWindowHeight;
    return Size(
      width.clamp(minWindowWidth, maxWindowWidth),
      height.clamp(minWindowHeight, maxWindowHeight),
    );
  }

  Future<void> setPosition(Offset offset) async {
    await getIt<KeyValueStorage>().set(
      KVKeys.windowPosition,
      jsonEncode({
        dx: offset.dx,
        dy: offset.dy,
      }),
    );
  }

  Future<Offset?> getPosition() async {
    final position = await getIt<KeyValueStorage>().get(KVKeys.windowPosition);
    if (position == null) {
      return null;
    }
    final offset = json.decode(position);
    return Offset(offset[dx], offset[dy]);
  }
}
