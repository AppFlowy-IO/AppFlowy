import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';

class WindowSizeManager {
  static const double minWindowHeight = 600.0;
  static const double minWindowWidth = 800.0;

  static const width = 'width';
  static const height = 'height';

  static const String dx = 'dx';
  static const String dy = 'dy';

  Future<void> setSize(Size size) async {
    final windowSize = {
      height: max(size.height, minWindowHeight),
      width: max(size.width, minWindowWidth),
    };

    await getIt<KeyValueStorage>().set(
      KVKeys.windowSize,
      jsonEncode(windowSize),
    );
  }

  Future<Size> getSize() async {
    final defaultWindowSize = jsonEncode({height: 600.0, width: 800.0});
    final windowSize = await getIt<KeyValueStorage>().get(KVKeys.windowSize);
    final size = json.decode(
      windowSize ?? defaultWindowSize,
    );
    return Size(size[width]!, size[height]!);
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
